{-# LANGUAGE LambdaCase #-}
{-# LANGUAGE OverloadedStrings #-}

module Main where

import Data.List (isInfixOf, sort)
import Snapshot
  ( ExtensionKind (..)
  , SnapshotError (..)
  , buildSnapshot
  , fileExtensionKind
  , isPrivatePath
  , isWalkFile
  , snapshotFiles
  )
import System.Directory (doesDirectoryExist, getCurrentDirectory)
import System.FilePath ((</>), normalise, takeDirectory)
import Test.Tasty (TestTree, defaultMain, testGroup)
import Test.Tasty.HUnit (Assertion, assertBool, assertFailure, testCase, (@?=))
import qualified Data.Map.Strict as Map
import qualified Data.Text as Text

main :: IO ()
main = do
  fixtureRoot <- resolveFixtureRoot
  defaultMain (tests fixtureRoot)

tests :: FilePath -> TestTree
tests fixtureRoot =
  testGroup
    "Snapshot"
    [ testGroup
        "buildSnapshot"
        [ testCase "loads a valid project" $
            testValidProject (fixture fixtureRoot "valid")
        , testCase "detects namespace collisions" $
            testCollision (fixture fixtureRoot "collision")
        , testCase "rejects an invalid root" $
            testInvalidRoot (fixture fixtureRoot "no-such-root")
        , testCase "skips ignored directories" $
            testIgnoredDirs (fixture fixtureRoot "ignored-dirs")
        , testCase "includes private files" $
            testPrivateFiles (fixture fixtureRoot "valid")
        , testCase "includes deps directory" $
            testDepsIncluded (fixture fixtureRoot "valid")
        , testCase "stores file contents in the map" $
            testFileContents (fixture fixtureRoot "valid")
        ]
    , testGroup
        "pure helpers"
        [ testCase "isWalkFile recognises Walk extensions" $
            mapM_ assertWalkFile
              [ ("main.fun", True)
              , ("profile.str", True)
              , ("status.enm", True)
              , ("contract.req", True)
              , ("README.md", False)
              , ("notes.txt", False)
              ]
        , testCase "isPrivatePath detects underscore-prefixed names" $
            mapM_ assertPrivatePath
              [ ("_helper.fun", True)
              , ("greet.fun", False)
              , ("user/profile.str", False)
              ]
        , testCase "fileExtensionKind maps extensions to kinds" $
            mapM_ assertExtensionKind
              [ ("main.fun", Just Fun)
              , ("activate.met", Just Met)
              , ("user.str", Just Str)
              , ("status.enm", Just Enm)
              , ("Printable.req", Just Req)
              , ("README.md", Nothing)
              ]
        ]
    ]

resolveFixtureRoot :: IO FilePath
resolveFixtureRoot = do
  cwd <- getCurrentDirectory
  let candidates =
        [ cwd </> "test/fixtures"
        , cwd </> "walk-compiler/test/fixtures"
        , takeDirectory cwd </> "test/fixtures"
        ]
  findExisting candidates

findExisting :: [FilePath] -> IO FilePath
findExisting (path : rest) = do
  exists <- doesDirectoryExist path
  if exists
    then pure path
    else findExisting rest
findExisting [] =
  fail "Could not locate test/fixtures (run via cabal test from walk-compiler/)"

fixture :: FilePath -> FilePath -> FilePath
fixture root name = root </> name

testValidProject :: FilePath -> Assertion
testValidProject root = do
  result <- buildSnapshot root
  case result of
    Left err ->
      assertFailure $ "expected success, got: " ++ show err
    Right snap -> do
      let files = Map.keys (snapshotFiles snap)
      Map.size (snapshotFiles snap) @?= 5
      mapM_ (\path -> assertBool (path ++ " missing") (path `elem` files)) expectedValidFiles

testCollision :: FilePath -> Assertion
testCollision root = do
  result <- buildSnapshot root
  case result of
    Left (NamespaceCollision dir base conflicts) -> do
      normalise dir @?= "."
      base @?= "status"
      sort conflicts @?= ["status.enm", "status.str"]
    Left err ->
      assertFailure $ "expected NamespaceCollision, got: " ++ show err
    Right _ ->
      assertFailure "expected NamespaceCollision, got success"

testInvalidRoot :: FilePath -> Assertion
testInvalidRoot root = do
  result <- buildSnapshot root
  case result of
    Left (InvalidRoot path) ->
      path @?= root
    _ ->
      assertFailure "expected InvalidRoot"

testIgnoredDirs :: FilePath -> Assertion
testIgnoredDirs root = do
  result <- buildSnapshot root
  case result of
    Left err ->
      assertFailure $ "expected success, got: " ++ show err
    Right snap -> do
      let files = Map.keys (snapshotFiles snap)
      Map.size (snapshotFiles snap) @?= 1
      files @?= ["main.fun"]
      assertBool ".git paths must not appear" (not $ any (".git" `isInfixOf`) files)

testPrivateFiles :: FilePath -> Assertion
testPrivateFiles root = do
  result <- buildSnapshot root
  case result of
    Right snap ->
      Map.member "_helper.fun" (snapshotFiles snap) @?= True
    Left err ->
      assertFailure $ "expected success, got: " ++ show err

testDepsIncluded :: FilePath -> Assertion
testDepsIncluded root = do
  result <- buildSnapshot root
  case result of
    Right snap ->
      Map.member "deps/lib/helper.fun" (snapshotFiles snap) @?= True
    Left err ->
      assertFailure $ "expected success, got: " ++ show err

testFileContents :: FilePath -> Assertion
testFileContents root = do
  result <- buildSnapshot root
  case result of
    Right snap -> do
      let contents = snapshotFiles snap Map.! "main.fun"
      Text.isInfixOf "Hello, World!" contents @?= True
    Left err ->
      assertFailure $ "expected success, got: " ++ show err

expectedValidFiles :: [FilePath]
expectedValidFiles =
  [ "main.fun"
  , "greet.fun"
  , "user/profile.str"
  , "_helper.fun"
  , "deps/lib/helper.fun"
  ]

assertWalkFile :: (FilePath, Bool) -> Assertion
assertWalkFile (path, expected) =
  isWalkFile path @?= expected

assertPrivatePath :: (FilePath, Bool) -> Assertion
assertPrivatePath (path, expected) =
  isPrivatePath path @?= expected

assertExtensionKind :: (FilePath, Maybe ExtensionKind) -> Assertion
assertExtensionKind (path, expected) =
  fileExtensionKind path @?= expected
