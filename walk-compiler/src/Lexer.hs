{-# Language OverloadedStrings #-}
module Lexer
    ( Parser
    , sc
    , lexeme
    , symbol
    , parens
    , braces
    , identifier
    , identifierText
    , keyword
    , typeName
    , stringParts
    ) where

import AST (StringPart (..))
import Data.Text (Text)
import Data.Void (Void)
import qualified Data.Text as Text
import Text.Megaparsec
import Text.Megaparsec.Char
import qualified Text.Megaparsec.Char.Lexer as L

-- Core parser for compilation
type Parser = Parsec Void Text

-- Space consumer to consume trailing whitespace / comments
sc :: Parser ()
sc =
    L.space
      space1
      (L.skipLineComment "#")   -- single line comments
      empty                     -- no handle for block comments yet

-- Consume trailing whitespace
lexeme :: Parser a -> Parser a
lexeme = L.lexeme sc

-- Parses fixed literal string token; consumes trailing whitespace
symbol :: Text -> Parser Text
symbol = L.symbol sc

-- Encloses a target parser within literal matching parentheses
parens :: Parser a -> Parser a
parens = between (symbol "(") (symbol ")")

-- Encloses a target parser within literal matching braces
braces :: Parser a -> Parser a
braces = between (symbol "{") (symbol "}")

-- Parses a standard variable or component identifier
identifier :: Parser String
identifier = lexeme $ do
    first <- letterChar
    rest <- many alphaNumChar
    pure (first : rest)

-- Packaged variant of 'identifier' returning standard strict 'Text'
identifierText :: Parser Text
identifierText = Text.pack <$> identifier

-- Asserts and consumes a distinct strict language keyword
keyword :: Text -> Parser ()
keyword kw = lexeme $ do
    _ <- string kw
    notFollowedBy alphaNumChar

-- Alias parser for explicit types
typeName :: Parser Text
typeName = identifierText

-- Parses double-quoted string literals containing a mix of raw chunks
stringParts :: Parser [StringPart]
stringParts = lexeme $ between (char '"') (char '"') (many (try interpolation <|> literalChunk))
    where
        literalChunk =
            Literal . Text.pack <$> some (noneOf ['"', '$'])
        interpolation = do
            _ <- string "${"
            name <- identifierText
            _ <- char '}'
            pure (Interpolate name)
