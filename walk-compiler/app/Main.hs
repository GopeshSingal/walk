{-# LANGUAGE LambdaCase #-}

module Main where

import Parser (ParseError (..), parseSnapshot)
import Snapshot (SnapshotError (..), buildSnapshot, snapshotFiles)
import System.Environment (getArgs)
import System.Exit (exitFailure, exitSuccess)
import qualified Data.Map.Strict as Map

main :: IO ()
main = do
    args <- getArgs
    case args of
        [root] -> runProject root
        _      -> printUsage >> exitFailure

runProject :: FilePath -> IO ()
runProject root = do
    snapResult <- buildSnapshot root
    case snapResult of
        Left err -> do
            putStrLn "Snapshot failed:"
            putStrLn (formatSnapshotError err)
            exitFailure
        Right snap -> do
            let files = Map.keys (snapshotFiles snap)
            putStrLn $ "Loaded " ++ show files ++ " Walk files from " ++ root
            parseResult <- parseSnapshot snap
            case parseResult of
                Left err -> do
                    putStrLn "Parse failed:"
                    putStrLn (formatParseError err)
                    exitFailure
                Right asts -> do
                    putStrLn $ "Parsed " ++ show (Map.size asts) ++ " files:"
                    mapM_ (putStrLn . ("  " ++) . fst) (Map.toList asts)
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

formatParseError :: ParseError -> String
formatParseError = \case
    ParseFailed path msg ->
        "Parse error in " ++ path ++ ":\n" ++ msg
    UnsupportedExtension path kind ->
        "No parser yet for " ++ show kind ++ " in " ++ path

printUsage :: IO ()
printUsage =
    putStrLn "Usage: walk-compiler <project-root>"
