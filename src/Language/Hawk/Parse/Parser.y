{
module Language.Hawk.Parse.Parser where

import Language.Hawk.Parse.Lexer
import Language.Hawk.Syntax.AST
import Language.Hawk.Data.Node

import Data.Monoid

}

%name parseHk
%tokentype { Token }
%monad { Alex }
%lexer { lexwrap } { Token _ TokenEof }
%error { happyError }

%token
    ID_LOWER                  { Token _ (TokenIdLower _) }
    ID_CAP_USCORE             { Token _ (TokenIdCapUscore _) }
    ID_USCORE_NUM_TICK        { Token _ (TokenIdUScoreNumTick _) }
    ID_CAP_USCORE_NUM_TICK    { Token _ (TokenIdCapUScoreNumTick _) }
    
    
    INT     { Token _ (TokenInt  _)     }
    FLOAT   { Token _ (TokenFloat  _)   }
    CHAR    { Token _ (TokenChar  _)    }
    STRING  { Token _ (TokenString  _)  }
    
    MOD       { Token _ TokenModule }
    USE       { Token _ TokenUse }
    USE_QUAL  { Token _ TokenUseQualified }
    
    PUB     { Token _ TokenPublic   }
    PRIV    { Token _ TokenPrivate  }
    LINK    { Token _ TokenLink }
    
    FN      { Token _ TokenFunction }
    VAL     { Token _ TokenValue    }
    VAR     { Token _ TokenVariable }
    
    DO              { Token _ TokenDo }
    RETURN          { Token _ TokenReturn }
    
    '()'            { Token _ TokenParenPair }
    
    BIT_TY          { Token _ TokenBitTy }
    W8_TY           { Token _ TokenW8Ty }
    W16_TY          { Token _ TokenW16Ty }
    W32_TY          { Token _ TokenW32Ty }
    W64_TY          { Token _ TokenW64Ty }
    I8_TY           { Token _ TokenI8Ty }
    I16_TY          { Token _ TokenI16Ty }
    I32_TY          { Token _ TokenI32Ty }
    I64_TY          { Token _ TokenI64Ty }
    F32_TY          { Token _ TokenF32Ty }
    F64_TY          { Token _ TokenF64Ty }
    CHAR_TY         { Token _ TokenCharTy }
    
    '::'            { Token _ TokenDblColon }
    
    ':='            { Token _ TokenFuncDef }
    ':-'            { Token _ TokenTypeDec }
    ':~'            { Token _ TokenTypeClass }
    ':+'            { Token _ TokenImplement }
    
    '<-'            { Token _ TokenLArrow }
    '<='            { Token _ TokenThickLArrow }
    '->'            { Token _ TokenRArrow }
    '=>'            { Token _ TokenThickRArrow }
    '<:'            { Token _ TokenSubtype }
    
    '`'             { Token _ TokenGrave }
    '~'             { Token _ TokenTilde }
    '!'     { Token _ TokenExclaim }
    '?'     { Token _ TokenQuestion }
    '@'     { Token _ TokenAt }
    '#'     { Token _ TokenPound }
    '$'     { Token _ TokenDollar }
    '%'     { Token _ TokenPercent }
    '^'     { Token _ TokenCaret }
    '&'     { Token _ TokenAmpersand }
    
    '('     { Token _ TokenLParen }
    ')'     { Token _ TokenRParen }
    '['     { Token _ TokenLBracket }
    ']'     { Token _ TokenRBracket }
    '{'     { Token _ TokenLCurlyBrace }
    '}'     { Token _ TokenRCurlyBrace }
    '|'     { Token _ TokenBar }
    
    ':'     { Token _ TokenColon }
    ';'     { Token _ TokenSemicolon }
    '.'     { Token _ TokenPeriod }
    ','     { Token _ TokenComma }
    '<'     { Token _ TokenLesser }
    '>'     { Token _ TokenGreater }
    
    '*'     { Token _ TokenStar }
    '/'     { Token _ TokenSlash }
    '+'     { Token _ TokenPlus }
    '-'     { Token _ TokenMinus }
    '='     { Token _ TokenEquals }
    
    OPEN_BLOCK    { Token _ TokenOpenBlock }
    CLOSE_BLOCK   { Token _ TokenCloseBlock }
    OPEN_STMT     { Token _ TokenOpenStmt }
    CLOSE_STMT    { Token _ TokenCloseStmt }

%%

trans_unit :: { HkTranslUnitNode }
  : root_mod { HkTranslUnit $1 (nodeInfo $1) }
  
root_mod :: { HkRootModuleNode }
  : MOD dotted_mod_id ext_stmts { HkRootModule $2 $3 (nodeInfo $1 <> nodesInfo $3)  }


-- -----------------------------------------------------------------------------
-- Hawk Parser "General"  
  
ty_id :: { HkIdentNode }
  : ID_CAP_USCORE           { HkIdent (getTokId $1) (nodeInfo $1) }
  | ID_CAP_USCORE_NUM_TICK  { HkIdent (getTokId $1) (nodeInfo $1) }
  
tyvar_id :: { HkIdentNode }
  : ID_LOWER                { HkIdent (getTokId $1) (nodeInfo $1) }

obj_id :: { HkIdentNode }
  : ID_LOWER                { HkIdent (getTokId $1) (nodeInfo $1) }
  | ID_USCORE_NUM_TICK      { HkIdent (getTokId $1) (nodeInfo $1) }

-- -----------------------------------------------------------------------------
-- | Hawk Parser "External Statments"

ext_stmt :: { HkExtStmtNode }
  : mod_dec       { $1 }
  | import_dec    { $1 }
  
ext_stmts :: { [HkExtStmtNode] }
  : ext_stmt                { [$1] }
  | ext_stmts ext_stmt      { $1 ++ [$2] }
  
ext_block :: { HkExtBlockNode }
  : '{' '}'                     { HkExtBlock [] (nodeInfo $1 <> nodeInfo $2) }
  | '{' ext_stmts '}'           { HkExtBlock $2 (nodeInfo $1 <> nodeInfo $3) }


  
vis_tag :: { HkVisibilityTagNode }
  : PUB                     { HkPublic  (nodeInfo $1) }
  | PRIV                    { HkPrivate (nodeInfo $1) }

-- -----------------------------------------------------------------------------
-- | Hawk Parser "Module"

mod_dec :: { HkExtStmtNode }
  : MOD dotted_mod_id ':' ext_block { HkModDef (HkPublic (nodeInfo $1)) $2 $4 ((nodeInfo $1) <> (nodeInfo $4)) }
  | vis_tag MOD dotted_mod_id ':' ext_block { HkModDef $1 $3 $5 ((nodeInfo $1) <> (nodeInfo $5)) }

mod_id :: { HkIdentNode }
  : ID_CAP_USCORE           { HkIdent (getTokId $1) (nodeInfo $1) }  
  
dotted_mod_id :: { HkDottedIdentNode }
  : mod_id                          { [$1] }
  | dotted_mod_id '.' mod_id        { $1 ++ [$3] }

-- -----------------------------------------------------------------------------
-- Hawk Parser "Import"
  
import_dec :: { HkExtStmtNode }
  : USE      import_items                   { HkExtImport     (HkPrivate (nodeInfo $1)) $2 (nodeInfo $1 <> nodesInfo $2) }
  | USE_QUAL import_items                   { HkExtImportQual (HkPrivate (nodeInfo $1)) $2 (nodeInfo $1 <> nodesInfo $2) }
  | vis_tag USE      import_items           { HkExtImport     $1 $3 (nodeInfo $1 <> nodesInfo $3) }
  | vis_tag USE_QUAL import_items           { HkExtImportQual $1 $3 (nodeInfo $1 <> nodesInfo $3) }

import_items :: { HkImportItemsNode }
  : import_item                             { [$1] }
  | dotted_mod_id '(' import_specs ')'      { prefixImportItems $1 $3 }

import_item :: { HkImportItemNode }
  : dotted_mod_id                           { HkImportItem $1 Nothing (nodesInfo $1) }
  | dotted_mod_id '.' import_target         { HkImportItem ($1 ++ [$3]) Nothing (nodesInfo $1 <> nodeInfo $3) }
  
import_specs :: { HkImportItemsNode }
  : import_spec                             { $1 }
  | import_specs ',' import_spec            { $1 ++ $3 }
  
import_spec :: { HkImportItemsNode }
  : import_target                           { [HkImportItem [$1] Nothing (nodeInfo $1)] }
  | import_items                            { $1 }
  
import_target :: { HkIdentNode }
  : ID_CAP_USCORE_NUM_TICK                  { HkIdent (getTokId $1) (nodeInfo $1) }
  | ID_USCORE_NUM_TICK                      { HkIdent (getTokId $1) (nodeInfo $1) }
  | ID_LOWER                                { HkIdent (getTokId $1) (nodeInfo $1) }


-- -----------------------------------------------------------------------------
-- Hawk Parser "Function"

fn_dec :: { HkFnDecNode }
  : FN fn_id '::' typesig                   { HkFnDec (HkSymIdent $2 (nodeInfo $2)) $4 (nodeInfo $1 <> nodeInfo $4) }

fn_id :: { HkIdentNode }
  : ID_LOWER                                { HkIdent (getTokId $1) (nodeInfo $1) }
  | ID_USCORE_NUM_TICK                      { HkIdent (getTokId $1) (nodeInfo $1) }


-- -----------------------------------------------------------------------------
-- Hawk Parser "Type Signature"

typesig :: { HkTypeSigNode }
  : type_chain                              { mkTypeSig Nothing $1 (nodesInfo $1) }

type_chain :: { [HkTypeNode] }
  : type                                    { [$1] }
  | type_chain '->' type                    { $1 ++ [$3] }

type :: { HkTypeNode }
  : prim_type                               { HkTyPrimType $1 (nodeInfo $1) }

-- -----------------------------------------------------------------------------
-- Hawk Parser "Primitive Types"

prim_type :: { HkPrimTypeNode }
  : '()'                                    { HkTyUnit (nodeInfo $1) }
  | BIT_TY                                  { HkTyBit (nodeInfo $1) }
  | W8_TY                                   { HkTyW8 (nodeInfo $1) }
  | W16_TY                                  { HkTyW16 (nodeInfo $1) }
  | W32_TY                                  { HkTyW32 (nodeInfo $1) }
  | W64_TY                                  { HkTyW64 (nodeInfo $1) }
  | I8_TY                                   { HkTyI8 (nodeInfo $1) }
  | I16_TY                                  { HkTyI16 (nodeInfo $1) }
  | I32_TY                                  { HkTyI32 (nodeInfo $1) }
  | I64_TY                                  { HkTyI64 (nodeInfo $1) }
  | F32_TY                                  { HkTyF32 (nodeInfo $1) }
  | F64_TY                                  { HkTyF64 (nodeInfo $1) }
  | CHAR_TY                                 { HkTyChar (nodeInfo $1) }

{


getTokId (Token _ (TokenIdLower s))            = s
getTokId (Token _ (TokenIdCapUscore s))        = s
getTokId (Token _ (TokenIdUScoreNumTick s))    = s
getTokId (Token _ (TokenIdCapUScoreNumTick s)) = s

getTokInt     (Token _ (TokenInt s))    = s
getTokString  (Token _ (TokenString s)) = s

lexwrap :: (Token -> Alex a) -> Alex a
lexwrap = (alexMonadScan' >>=)

happyError :: Token -> Alex a
happyError tok@(Token (TokenInfo n p _) t) =
  alexError' p ("parse error at token '" ++ show t ++ "'" ++ "\n" ++ show tok)

parse :: FilePath -> String -> Either String HkTranslUnitNode
parse = runAlex' parseHk

parseFile :: FilePath -> IO (Either String HkTranslUnitNode)
parseFile p = readFile p >>= return . parse p


}