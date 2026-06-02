{-# LANGUAGE OverloadedStrings #-}

module Parser
    ( ParseError (..)
    , parseFunFile
    , parseStrFile
    , parseEnmFile
    , parseSnapshot)
    where
import AST
import Control.Concurrent.Async (mapConcurrently)
import Data.Functor ((<&>))
import Data.Map.Strict (Map)
import Data.Text (Text)
import Data.Void (Void)
import Lexer
import Snapshot (ExtensionKind (..), ProjectSnapshot (..), fileExtensionKind, snapshotFiles)
import Text.Megaparsec (Parsec, eof, errorBundlePretty, many, runParser, optional)
import qualified Data.Map.Strict as Map

data ParseError
    = ParseFailed FilePath String
    | UnsupportedExtension FilePath ExtensionKind
    deriving (Eq, Show)

type P = Parsec Void Text

runParse :: FilePath -> Text -> P a -> Either ParseError a
runParse path text p =
    case runParser (p <* eof) path text of
        Left bundle -> Left (ParseFailed path (errorBundlePretty bundle))
        Right ast -> Right ast

parseFunFile :: FilePath -> Text -> Either ParseError FunFile
parseFunFile path text = runParse path text funFile

parseStrFile :: FilePath -> Text -> Either ParseError StrFile
parseStrFile path text = runParse path text strFile

parseEnmFile :: FilePath -> Text -> Either ParseError EnmFile
parseEnmFile path text = runParse path text enmFile

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
                FunAST <$> parseFunFile path text <&> (path,)
            Just Str ->
                StrAST <$> parseStrFile path text <&> (path,)
            Just Enm ->
                EnmAST <$> parseEnmFile path text <&> (path,)
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

strFile :: P StrFile
strFile = sc *> do
    fields <- many (optional sc *> fieldDecl)
    pure (StrFile fields)

fieldDecl :: P FieldDecl
fieldDecl = do
    name <- identifierText
    _    <- symbol ":"
    FieldDecl name <$> typeName

enmFile :: P EnmFile
enmFile = sc *> do
    variants <- many (optional sc *> variantName)
    pure (EnmFile variants)

variantName :: P Text
variantName = identifierText

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
