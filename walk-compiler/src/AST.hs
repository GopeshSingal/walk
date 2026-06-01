module AST
    ( WalkAST (..)
    , FunFile (..)
    , StrFile (..)
    , EnmFile (..)
    , ContractDecl (..)
    , FieldDecl (..)
    , Stmt (..)
    , StringPart (..)
    ) where

import Data.Text (Text)

data WalkAST
    = FunAST FunFile
    | StrAST StrFile
    | EnmAST EnmFile
    deriving (Eq, Show)

data FunFile = FunFile
    { funIns :: [ContractDecl]
    , funOuts :: [ContractDecl]
    , funStmts :: [Stmt]
    }
    deriving (Eq, Show)

data StrFile = StrFile
    { strFields :: ![FieldDecl]
    }
    deriving (Eq, Show)

data EnmFile = EnmFile
    { enmVariants :: ![Text]
    }
    deriving (Eq, Show)

data ContractDecl = ContractDecl
    { contractName :: !Text
    , contractType :: !Text
    }
    deriving (Eq, Show)

data FieldDecl = FieldDecl
    { fieldName :: !Text
    , fieldType :: !Text
    }
    deriving (Eq, Show)

newtype Stmt
    = PrintStmt [StringPart]
    deriving (Eq, Show)

data StringPart
    = Literal !Text
    | Interpolate !Text
    deriving (Eq, Show)
