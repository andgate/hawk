{-# LANGUAGE ConstraintKinds #-}
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE TypeSynonymInstances #-}
module Language.Hawk.Parse.Helpers where

import Control.Applicative
import Control.Arrow
import Control.Monad.State
import qualified Data.ByteString.UTF8 as UTF8
import Text.Parser.Char
import Text.Parser.Combinators
import Text.Parser.LookAhead
import Text.PrettyPrint.ANSI.Leijen (pretty, Pretty)
import Text.Trifecta.Combinators
import Text.Trifecta.Delta
import qualified Text.Trifecta.Parser as Trifecta
import Text.Trifecta.Result

import Language.Hawk.Parse.Layout
import qualified Language.Hawk.Report.Annotation as A
import qualified Language.Hawk.Report.Region as R


type IParser a = StateT LayoutEnv Trifecta.Parser a

type MonadicParsing m
  = (DeltaParsing m, LayoutParsing m, Monad m)


defDelta :: String -> Delta
defDelta fn =
  Directed (UTF8.fromString fn) 0 0 0 0


parseFromFile :: MonadIO m => IParser a -> String -> m (Maybe a)
parseFromFile p fn =
  Trifecta.parseFromFile (evalStateT p defLayoutEnv) fn
  

parseFromFileEx :: MonadIO m => IParser a -> String -> m (Result a)
parseFromFileEx p fn =
  Trifecta.parseFromFileEx (evalStateT p defLayoutEnv) fn


parseString :: IParser a -> String -> String -> Result a
parseString p fn str =
  Trifecta.parseString (evalStateT p defLayoutEnv) (defDelta fn) str


-- Test Parser with String
(#) :: Pretty a => IParser a -> String -> IO ()
(#) parser input =
  do  putStr "\nFile parsed:\n"
      case (parseString parser "(test)" input) of
        Success result -> print $ pretty result
        Failure errMsg -> error $ show errMsg


-- -----------------------------------------------------------------------------
-- Token

token :: MonadicParsing m => m a -> m a
token p = 
  p <* optional ws

-- -----------------------------------------------------------------------------
-- Identifiers
-- 
-- The basic identifiers for each name.

-- A constructor id must start with a lowercase letter, and the body may
-- consist of upper and lowercase letters, numbers, underscores, and tick marks.
varId :: MonadicParsing m => m String
varId = 
  token lowNumSymId

-- A constructor id must start with an uppercase letter, and the body may
-- consist of upper and lowercase letters, numbers, underscores, and tick marks.
conId :: MonadicParsing m => m String
conId = 
  token capNumSymId


-- A module id must start with an uppercase letter, and the body may
-- consist of upper and lowercase letters
modId :: MonadicParsing m => m String
modId = 
  token capId


-- Bases for each id.
capId :: MonadicParsing m => m String
capId =
  makeId (try upper) letter

capNumSymId :: MonadicParsing m => m String
capNumSymId =
  makeId (try upper) idBodyChar

lowNumSymId :: MonadicParsing m => m String
lowNumSymId =
  makeId (try lower) idBodyChar


idBodyChar :: MonadicParsing m => m Char
idBodyChar =
  alphaNum  <|> char '_' <|> char '`'

-- Make an id parser given a parser for the first character and a body character.
makeId :: MonadicParsing m => m Char -> m Char -> m String
makeId firstChar bodyChar =
  (:) <$> firstChar <*> many bodyChar 


-- -----------------------------------------------------------------------------
-- Numbers


-- -----------------------------------------------------------------------------
-- Characters


charTok :: MonadicParsing m => Char -> m Char
charTok str =
  token $ char str

stringTok :: MonadicParsing m => String -> m String
stringTok str =
  token $ string str


-- -----------------------------------------------------------------------------
-- Common Symbols

equals :: MonadicParsing m => m String
equals =
  stringTok "=" <?> "an equals sign '='"
  
vardefsym :: MonadicParsing m => m String
vardefsym =
  stringTok "^=" <?> "a variable definition symbol '^='"


condefsym :: MonadicParsing m => m String
condefsym =
  stringTok ":-" <?> "a type definition symbol ':-'"
    
fndefsym :: MonadicParsing m => m String
fndefsym =
  stringTok ":=" <?> "a function definition symbol ':='"


rightArrow :: MonadicParsing m => m String
rightArrow = 
  stringTok "->" <?> "an arrow '->'"


hasType :: MonadicParsing m => m String
hasType =
  stringTok "::" <?> "the \"has type\" symbol '::'"
    
    
comma :: MonadicParsing m => m String
comma =
  stringTok "," <?> "a comma symbol ','"
  
  
period :: MonadicParsing m => m String
period =
  stringTok "." <?> "a period symbol '.'"

-- -----------------------------------------------------------------------------
-- Grouping

commitIf :: MonadicParsing m => m b -> m a -> m a
commitIf check p =
    commit <|> try p
  where
    commit =
      try (lookAhead check) >> p


spaceySepBy :: MonadicParsing m => m a -> m b -> m [a]
spaceySepBy p sep = 
  option [] ((try p) `spaceySepBy1` sep)


spaceySepBy1 :: MonadicParsing m => m a -> m b -> m [a]
spaceySepBy1 p sep =
  (:) <$> p <*> p `spaceyPrefixBy` sep
    
    
spaceyPrefixBy :: MonadicParsing m => m a -> m b -> m [a]
spaceyPrefixBy p sep =
  many $ commitIf (sep) (sep >> p)

  
arrowSep1 :: MonadicParsing m => m a -> m [a]
arrowSep1 p =
  p `spaceySepBy1` rightArrow
  


commaSep :: MonadicParsing m => m a -> m [a]
commaSep p =
  p `spaceySepBy` comma
  
  
commaSep1 :: MonadicParsing m => m a -> m [a]
commaSep1 p =
  p `spaceySepBy1` comma
  
  
periodSep :: MonadicParsing m => m a -> m [a]
periodSep p =
  p `spaceySepBy` period
  
  
periodSep1 :: MonadicParsing m => m a -> m [a]
periodSep1 p =
  p `spaceySepBy1` period


spaceSep :: MonadicParsing m => m a -> m [a]
spaceSep p =
  spaceSep1 p <|> pure []
 

spaceSep1 :: MonadicParsing m => m a -> m [a]
spaceSep1 p =
  (:) <$> p <*> spacePrefix p


spacePrefix :: MonadicParsing m => m a -> m [a]
spacePrefix p =
  many (try p)

  
  

-- -----------------------------------------------------------------------------
-- Containers

surround :: MonadicParsing m => String -> String -> String -> m a -> m a
surround l r name p =
  try (stringTok l) *> p <* (stringTok r <?> unwords ["a closing", name, " '", show r, "'"])


parens :: MonadicParsing m => m a -> m a
parens =
  surround "(" ")" "paren"
  

brackets :: MonadicParsing m => m a -> m a
brackets =
  surround "[" "]" "bracket"

 
braces :: MonadicParsing m => m a -> m a
braces =
  surround "{" "}" "brace"
  

chevrons :: MonadicParsing m => m a -> m a
chevrons =
  surround "<" ">" "chevron"
  

-- -----------------------------------------------------------------------------
-- Location

locate :: MonadicParsing m => m a -> m (A.Located a)
locate p = do
  p1 <- position
  r <- p
  p2 <- position
  return $ A.A (R.mkRegion p1 p2) r
  
  
withRegion :: MonadicParsing m => m a -> (R.Region -> a -> b) -> m b
withRegion p func = do
  p1 <- position
  result <- p
  region <- R.mkRegion p1 <$> position
  return $ func region result
  