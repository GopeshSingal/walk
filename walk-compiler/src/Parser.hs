{-# LANGUAGE OverloadedStrings #-}

module Parser
    ( ParseError (..)
    , parseFunFile
    , parseSnapshot)
    where
import AST
import Control.Concurrent.Async (mapConcurrently)
import Data.Map.Strict (Map)
import Data.Text (Text)
import Data.Void (Void)
import Lexer
import Snapshot (ExtensionKind (..), ProjectSnapshot (..), fileExtensionKind, snapshotFiles)
import Text.Megaparsec (Parsec, eof, errorBundlePretty, many, runParser, try, optional)
import qualified Data.Map.Strict as Map

data ParseError
    = ParseFailed FilePath String
    | UnsupportedExtension FilePath ExtensionKind
    deriving (Eq, Show)

type P = Parsec Void Text

parseFunFile :: FilePath -> Text -> Either ParseError FunFile
parseFunFile path text =
    case runParser (funFile <* eof) path text of
        Left bundle -> Left (ParseFailed path (errorBundlePretty bundle))
        Right ast   -> Right ast

parseSnapshot :: ProjectSnapshot -> IO (Either ParseError (Map FilePath WalkAST))
parseSnapshot snap =
    let entries = Map.toList (snapshotFiles snap)
        in parseEntries entries

parseEntries :: [(FilePath, Text)] -> IO (Either ParseError (Map FilePath WalkAST))
parseEntries [] = pure (Right Map.empty)
parseEntries entries = do
    results <- mapConcurrently parseEntry entries
    pure (foldResults results)

parseEntry :: (FilePath, Text) -> IO (Either ParseError (FilePath, WalkAST))
parseEntry (path, text) =
    pure $
        case fileExtensionKind path of
            Just Fun ->
                case parseFunFile path text of
                    Left err -> Left err
                    Right parsed -> Right (path, FunAST parsed)
            Just kind ->
                Left (UnsupportedExtension path kind)
            Nothing ->
                Left (ParseFailed path "not a Walk source file")

foldResults :: [Either ParseError (FilePath, WalkAST)] -> Either ParseError (Map FilePath WalkAST)
foldResults results = 
    case sequence results of
        Left err -> Left err
        Right pairs -> Right (Map.fromList pairs)

funFile :: P FunFile
funFile = sc *> do
    ins <- many (optional sc *> contractIn)
    outs <- many (optional sc *> contractOut)
    stmts <- many (optional sc *> stmt)
    pure (FunFile ins outs stmts)

contractIn :: P ContractDecl
contractIn = do
    keyword "in"
    name <- identifierText
    _    <- symbol ":"
    ContractDecl name <$> typeName 

contractOut :: P ContractDecl
contractOut = do
    keyword "out"
    name <- identifierText
    _    <- symbol ":"
    ContractDecl name <$> typeName 

stmt :: P Stmt
stmt = printStmt

printStmt :: P Stmt
printStmt = do
    keyword "print"
    parts <- parens stringParts
    pure (PrintStmt parts)
