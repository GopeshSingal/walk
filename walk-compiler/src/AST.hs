module AST
    ( WalkAST (..)
    , FunFile (..)
    , ContractDecl (..)
    , Stmt (..)
    , StringPart (..)
    ) where

import Data.Text (Text)

newtype WalkAST
    = FunAST FunFile
    deriving (Eq, Show)

data FunFile = FunFile
    { funIns :: [ContractDecl]
    , funOuts :: [ContractDecl]
    , funStmts :: [Stmt]
    }
    deriving (Eq, Show)

data ContractDecl = ContractDecl
    { contractName :: !Text
    , contractType :: !Text
    }
    deriving (Eq, Show)

newtype Stmt
    = PrintStmt [StringPart]
    deriving (Eq, Show)

data StringPart
    = Literal !Text
    | Interpolate !Text
    deriving (Eq, Show)
