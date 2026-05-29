  {-# LANGUAGE OverloadedStrings #-}
  module Main where
  import AST
  import Parser (ParseError (..), parseFunFile)
  import System.Directory (doesDirectoryExist, getCurrentDirectory)
  import System.FilePath ((</>), takeDirectory)
  import Test.Tasty (TestTree, defaultMain, testGroup)
  import Test.Tasty.HUnit (Assertion, assertFailure, testCase, (@?=))
  import qualified Data.Text.IO as TIO
  main :: IO ()
  main = do
    fixtureRoot <- resolveFixtureRoot
    defaultMain (tests fixtureRoot)
  tests :: FilePath -> TestTree
  tests fixtureRoot =
    testGroup
      "Parser"
      [ testGroup
          "parseFunFile"
          [ testCase "parses main.fun" $
              testMainFun (fixture fixtureRoot "valid/main.fun")
          , testCase "parses greet.fun" $
              testGreetFun (fixture fixtureRoot "valid/greet.fun")
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
    if exists then pure path else findExisting rest
  findExisting [] =
    fail "Could not locate test/fixtures"
  fixture :: FilePath -> FilePath -> FilePath
  fixture root rel = root </> rel
  testMainFun :: FilePath -> Assertion
  testMainFun path = do
    text <- TIO.readFile path
    case parseFunFile path text of
      Left err ->
        assertFailure $ show err
      Right (FunFile ins outs [PrintStmt parts]) -> do
        ins @?= []
        outs @?= []
        parts @?= [Literal "Hello, World!"]
      Right _ ->
        assertFailure "unexpected AST shape"
  testGreetFun :: FilePath -> Assertion
  testGreetFun path = do
    text <- TIO.readFile path
    case parseFunFile path text of
      Left err ->
        assertFailure $ show err
      Right (FunFile [ContractDecl "name" "String"] outs [PrintStmt parts]) -> do
        outs @?= []
        parts @?= [Literal "Hello, ", Interpolate "name", Literal "!"]
      Right _ ->
        assertFailure "unexpected AST shape"
