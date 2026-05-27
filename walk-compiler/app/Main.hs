{-# LANGUAGE LambdaCase #-}

module Main where

import Snapshot (SnapshotError (..), buildSnapshot, snapshotFiles)
import System.Environment (getArgs)
import System.Exit (exitFailure, exitSuccess)
import System.FilePath (FilePath)
import qualified Data.Map.Strict as Map

main :: IO ()
main = do
    args <- getArgs
    case args of
        [root] -> runSnapshot root
        _      -> printUsage >> exitFailure

runSnapshot :: FilePath -> IO ()
runSnapshot root = do
    result <- buildSnapshot root
    case result of
        Left err -> do
            putStrLn "Snapshot failed:"
            putStrLn (formatSnapshotError err)
            exitFailure
        Right snap -> do
            let files = Map.keys (snapshotFiles snap)
            putStrLn $ "Loaded " ++ show (length files) ++ " Walk files from " ++ root ++ ":"
            mapM_ (putStrLn . (" " ++)) files
            exitSuccess

formatSnapshotError :: SnapshotError -> String
formatSnapshotError = \case
    InvalidRoot path ->
        "Invalid project root: " ++ path
    NamespaceCollision dir base conflicts ->
        unlines
            [ "Namespace collision in " ++ dir ++ ": base name '" ++ base ++ "' is used by:"
            , unlines (map ("  - " ++) conflicts)
            ]
    ReadFailed path msg ->
        "Failed to read " ++ path ++ ": " ++ msg
printUsage :: IO ()
printUsage =
    putStrLn "Usage: walk-compiler <project-root>"
