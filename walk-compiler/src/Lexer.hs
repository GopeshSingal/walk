{-# Language OverloadedStrings #-}

module Lexer where

import Data.Void (Void)
import Data.Text (Text)
import Text.Megaparsec
import Text.Megaparsec.Char
import qualified Text.Megaparsec.Char.Lexer as L

-- The core parser type for the compilation
type Parser = Parsec Void Text

-- Space consumer to ignore whitespace and comments
sc :: Parser()
sc = L.space
    space1                      -- how to consume whitespace
    (L.skipLineComment "#")     -- how to consume comments
    empty                       -- no block comments for now

-- Lexeme wrapper to consume trailing whitespace
lexeme :: Parser a -> Parser a
lexeme = L.lexeme sc

symbol :: Text -> Parser Text
symbol = L.symbol sc

parens :: Parser a -> Parser a
parens = between (symbol "(") (symbol ")")

braces :: Parser a -> Parser a
braces = between (symbol "{") (symbol "}")

identifier :: Parser String
identifier = lexeme $ do
    first <- letterChar
    rest <- many alphaNumChar
    return (first : rest)


keyword :: Text -> Parser ()
keyword kw = lexeme $ do
    _ <- string kw
    notFollowedBy alphaNumChar
