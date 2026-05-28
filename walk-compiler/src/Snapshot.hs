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

-- List of valid Walk extensions
walkExtensions :: [String]
walkExtensions = [".fun", ".met", ".str", ".enm", ".req"]

data ExtensionKind
    = Fun
    | Met
    | Str
    | Enm
    | Req
    deriving (Eq, Ord, Show, Enum, Bounded)

-- Maps raw file path to corresponding ExtensionKind
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

-- Represents errors that may occur during snapshot
data SnapshotError
    = InvalidRoot FilePath                              -- provided root does not exist / not a directory
    | NamespaceCollision FilePath String [FilePath]     -- multiple files share the same name
    | ReadFailed FilePath String                        -- I/O disk reading error
    deriving (Eq, Show)

-- Final validated state from snapshot
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

-- Core orchestrator of snapshotting
-- 1. Validates the root path
-- 2. Discovers target files
-- 3. Enforce namespace constraints
-- 4. Reads content into a ProjectSnapshot
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

-- Recursively crawls directories from "current" to accumlate matching files
collectWalkFiles :: FilePath -> FilePath -> IO [FilePath]
collectWalkFiles root current = do
    entries <- listDirectory current
    foldMap (processEntry root current) entries

-- Processes and individual directory or file
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

-- Ensures that no two files share the exact same name
validateNamespaces :: [FilePath] -> Either SnapshotError [FilePath]
validateNamespaces paths =
    let sorted = sort paths
        grouped =
            groupBy
                (\a b ->
                    takeDirectory a == takeDirectory b
                        && takeBaseName a == takeBaseName b
                )
                -- Sort criteria groups paths by (Directory, Base Name)
                (sortOn (\p -> (takeDirectory p, takeBaseName p, p)) sorted)
     in case findFirstCollision grouped of
        Nothing -> Right sorted
        Just collision -> Left collision
    where
        -- Iterates through grouped sublists to find first occurence of a collision.
        findFirstCollision :: [[FilePath]] -> Maybe SnapshotError
        findFirstCollision = go
            where
                go [] = Nothing
                go (g : gs) =
                    case checkGroup g of
                        Just err -> Just err
                        Nothing -> go gs

                -- A list with >= 2 items means we have a collision
                checkGroup :: [FilePath] -> Maybe SnapshotError
                checkGroup group@(p : _ : _) =
                    Just
                        ( NamespaceCollision
                            (takeDirectory p)
                            (takeBaseName p)
                            (sort group)
                        )
                checkGroup _ = Nothing

-- Reads files into a strict Map
readAllFiles :: FilePath -> [FilePath] -> IO (Either SnapshotError (Map FilePath Text))
readAllFiles root = go Map.empty
    where
        go acc [] = pure (Right acc)
        go acc (relPath : rest) = do
            result <- try @IOException (TIO.readFile (root </> relPath))
            case result of
                Left ioErr -> pure (Left (ReadFailed relPath (show ioErr)))
                Right text -> go (Map.insert relPath text acc) rest
