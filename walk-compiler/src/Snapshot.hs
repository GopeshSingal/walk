{-# LANGUAGE OverloadedStrings #-}

module Snapshot
  (
    ProjectSnapshot (..)
  , SnapshotError (..)
  , buildSnapshot
  , walkExtensions
  , isWalkFile
  , isPrivatePath
  , fileExtensionKind
  , ExtensionKind (..)
  ) where

import Control.Exception (IOException, try)
import Data.List (groupBy, sort, sortOn)
import Data.Map.Strict (Map)
import Data.Text (Text)
import qualified Data.Map.Strict as Map
import qualified Data.Text.IO as TIO
import System.Directory (doesDirectoryExist, listDirectory)
import System.FilePath
  ( makeRelative
  , normalise
  , takeBaseName
  , takeDirectory
  , takeExtension
  , (</>)
  )

walkExtensions :: [String]
walkExtensions = [".fun", ".met", ".str", ".enm", ".req"]

data ExtensionKind
  = Fun
  | Met
  | Str
  | Enm
  | Req
  deriving (Eq, Ord, Show, Enum, Bounded)

fileExtensionKind :: FilePath -> Maybe ExtensionKind
fileExtensionKind path =
  case takeExtension path of
    ".fun" -> Just Fun
    ".met" -> Just Met
    ".str" -> Just Str
    ".enm" -> Just Enm
    ".req" -> Just Req
    _      -> Nothing

isWalkFile :: FilePath -> Bool
isWalkFile = (`elem` walkExtensions) . takeExtension

isPrivatePath :: FilePath -> Bool
isPrivatePath path =
  case takeBaseName path of
    ('_':_) -> True
    _       -> False

data SnapshotError
  = InvalidRoot FilePath
  | NamespaceCollision FilePath String [FilePath]
  | ReadFailed FilePath String
  deriving (Eq, Show)

data ProjectSnapshot = ProjectSnapshot
  { snapshotRoot  :: !FilePath
  , snapshotFiles :: !(Map FilePath Text)
  }
  deriving (Eq, Show)

ignoreDirs :: [FilePath]
ignoreDirs =
  [ ".git"
  , ".walk_bin"
  , "dist"
  , "dist-newstyle"
  , ".hie"
  ]

buildSnapshot :: FilePath -> IO (Either SnapshotError ProjectSnapshot)
buildSnapshot root = do
  rootExists <- doesDirectoryExist root
  if not rootExists
    then pure (Left (InvalidRoot root))
    else do
      relPaths <- collectWalkFiles root root
      case validateNamespaces relPaths of
        Left err         -> pure (Left err)
        Right validPaths -> do
          result <- readAllFiles root validPaths
          pure (fmap (ProjectSnapshot root) result)

collectWalkFiles :: FilePath -> FilePath -> IO [FilePath]
collectWalkFiles root current = do
  entries <- listDirectory current
  foldMap (processEntry root current) entries

processEntry :: FilePath -> FilePath -> FilePath -> IO [FilePath]
processEntry root current name = do
  let absPath = current </> name
  isDir <- doesDirectoryExist absPath
  if isDir
    then
      if name `elem` ignoreDirs
        then pure []
        else collectWalkFiles root absPath
    else
      if isWalkFile name
        then pure [normalise (makeRelative root absPath)]
        else pure []

validateNamespaces :: [FilePath] -> Either SnapshotError [FilePath]
validateNamespaces paths =
  let sorted = sort paths
      grouped =
        groupBy
          (\a b ->
             takeDirectory a == takeDirectory b
               && takeBaseName a == takeBaseName b)
          (sortOn (\p -> (takeDirectory p, takeBaseName p, p)) sorted)
   in case findFirstCollision grouped of
        Nothing        -> Right sorted
        Just collision -> Left collision
  where
    findFirstCollision :: [[FilePath]] -> Maybe SnapshotError
    findFirstCollision = go
      where
        go [] = Nothing
        go (g : gs) =
          case checkGroup g of
            Just err -> Just err
            Nothing  -> go gs
        checkGroup :: [FilePath] -> Maybe SnapshotError
        checkGroup group@(p : _ : _) =
          Just
            ( NamespaceCollision
                (takeDirectory p)
                (takeBaseName p)
                (sort group)
            )
        checkGroup _ = Nothing

readAllFiles :: FilePath -> [FilePath] -> IO (Either SnapshotError (Map FilePath Text))
readAllFiles root = go Map.empty
  where
    go acc [] = pure (Right acc)
    go acc (relPath : rest) = do
      result <- try @IOException (TIO.readFile (root </> relPath))
      case result of
        Left ioErr -> pure (Left (ReadFailed relPath (show ioErr)))
        Right text -> go (Map.insert relPath text acc) rest
