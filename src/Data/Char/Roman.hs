{-# LANGUAGE Safe #-}

{-|
Module      : Data.Char.Roman
Description : A module to print Roman numerals both in uppercase and lowercase.
Maintainer  : hapytexeu+gh@gmail.com
Stability   : experimental
Portability : POSIX

This module aims to convert Roman numerals to a String of unicode characters that
represent Roman numerals.

One can convert numbers to Roman numerals in uppercase and lowercase, and in 'Additive' and 'Subtractive' style.
-}

module Data.Char.Roman (
    -- * Data types to represent Roman numerals
    RomanLiteral(I, II, III, IV, V, VI, VII, VIII, IX, X, XI, XII, L, C, D, M)
  , RomanStyle(Additive, Subtractive)
    -- * Convert a number to Roman literals
  , toLiterals
  , romanLiteral, romanLiteral'
    -- * Convert a number to text
  , romanNumeral, romanNumeral'
  , romanNumber,  romanNumber'
  ) where

import Data.Bits((.|.))
import Data.Char(chr)
import Data.Char.Core(Ligate, ligateF)
import Data.Default(Default(def))
import Data.Text(Text, cons, empty)

import Test.QuickCheck.Arbitrary(Arbitrary(arbitrary), arbitraryBoundedEnum)

-- | The style to convert a number to a Roman numeral.
data RomanStyle
  = Additive -- ^ The additive style converts four to ⅠⅠⅠⅠ.
  | Subtractive -- ^ The subtractive style converts four to ⅠⅤ.
  deriving (Bounded, Enum, Eq, Show, Read)

instance Default RomanStyle where
    def = Subtractive

instance Arbitrary RomanStyle where
    arbitrary = arbitraryBoundedEnum

-- | Roman numerals for which a unicode character exists.
data RomanLiteral
  = I -- ^ The unicode character for the Roman numeral /one/: Ⅰ.
  | II -- ^ The unicode character for the Roman numeral /two/: Ⅱ.
  | III -- ^ The unicode character for the Roman numeral /three/: Ⅲ.
  | IV -- ^ The unicode character for the Roman numeral /four/: Ⅳ.
  | V -- ^ The unicode character for the Roman numeral /five/: Ⅴ.
  | VI -- ^ The unicode character for the Roman numeral /six/: Ⅵ.
  | VII -- ^ The unicode character for the Roman numeral /seven/: Ⅶ.
  | VIII -- ^ The unicode character for the Roman numeral /eight/: Ⅷ.
  | IX -- ^ The unicode character for the Roman numeral /nine/: Ⅸ.
  | X -- ^ The unicode character for the Roman numeral /ten/: Ⅹ.
  | XI -- ^ The unicode character for the Roman numeral /eleven/: Ⅺ.
  | XII -- ^ The unicode character for the Roman numeral /twelve/: Ⅻ.
  | L -- ^ The unicode character for the Roman numeral /fifty/: Ⅼ.
  | C -- ^ The unicode character for the Roman numeral /hundred/: Ⅽ.
  | D -- ^ The unicode character for the Roman numeral /five hundred/: Ⅾ.
  | M -- ^ The unicode character for the Roman numeral /thousand/: Ⅿ.
  deriving (Bounded, Enum, Eq, Show, Read)

_literals :: Integral i => RomanStyle -> [(i, [RomanLiteral] -> [RomanLiteral])]
_literals Additive = [
    (1000, (M:))
  , (500, (D:))
  , (100, (C:))
  , (50, (L:))
  , (10, (X:))
  , (5, (V:))
  , (1, (I:))
  ]
_literals Subtractive = [
    (1000, (M:))
  , (900, ([C,M]++))
  , (500, (D:))
  , (400, ([C,D]++))
  , (100, (C:))
  , (90, ([X,C]++))
  , (50, (L:))
  , (40, ([X,L]++))
  , (10, (X:))
  , (9, ([I,X]++))
  , (5, (V:))
  , (4, ([I,V]++))
  , (1, (I:))
  ]

_ligate :: [RomanLiteral] -> [RomanLiteral]
_ligate [] = []
_ligate (r:rs) = go r rs
    where go x [] = [x]
          go x (y:ys) = f x y ys
          f I I = go II
          f II I = skip III
          f I V = skip IV
          f V I = go VI
          f VI I = go VII
          f VII I = skip VIII
          f X I = go XI
          f I X = skip IX
          f XI I = go XII
          f x y = (x :) . go y
          skip = (. _ligate) . (:)

-- | Convert the given number with the given 'RomanStyle' and 'Ligate' style
-- to a sequence of 'RomanLiteral's, given the number can be represented
-- with Roman numerals (is strictly larger than zero).
toLiterals :: Integral i
  => RomanStyle -- ^ Specifies if the Numeral is 'Additive' or 'Subtractive' style.
  -> Ligate -- ^ Specifies if characters like @ⅠⅤ@ are joined to @Ⅳ@.
  -> i -- ^ The given number to convert.
  -> Maybe [RomanLiteral] -- ^ A list of 'RomanLiteral's if the given number can be specified
                          -- with Roman numerals, 'Nothing' otherwise.
toLiterals s c k
    | k > 0 = ligateF _ligate c (go k (_literals s))
    | otherwise = Nothing
    where go 0 _ = Just []
          go _ [] = Nothing
          go n va@((m, l):vs)
              | n >= m = l <$> go (n-m) va
              | otherwise = go n vs

_romanLiteral :: Int -> RomanLiteral -> Char
_romanLiteral = (chr .) . (. fromEnum) . (.|.)

-- | Convert the given 'RomanLiteral' object to a unicode character in
-- /uppercase/.
romanLiteral
  :: RomanLiteral -- ^ The given 'RomanLiteral' to convert.
  -> Char -- ^ A unicode character that represents the given 'RomanLiteral'.
romanLiteral = _romanLiteral 0x2160

-- | Convert the given 'RomanLiteral' object to a unicode character in
-- /lowercase/.
romanLiteral'
  :: RomanLiteral -- ^ The given 'RomanLiteral' to convert.
  -> Char -- ^ A unicode character that represents the given 'RomanLiteral'.
romanLiteral' = _romanLiteral 0x2170

_romanNumeral :: (RomanLiteral -> Char) -> [RomanLiteral] -> Text
_romanNumeral = (`foldr` empty) . (cons .)

-- | Convert a sequence of 'RomanLiteral' objects to a 'Text' object that
-- contains a sequence of corresponding Unicode characters which are Roman
-- numberals in /uppercase/.
romanNumeral
  :: [RomanLiteral] -- ^ The given list of 'RomanLiteral' objects to convert to a Unicode equivalent.
  -> Text -- ^ A 'Text' object that contains a sequence of unicode characters that represents the 'RomanLiteral's.
romanNumeral = _romanNumeral romanLiteral

-- | Convert a sequence of 'RomanLiteral' objects to a 'Text' object that
-- contains a sequence of corresponding Unicode characters which are Roman
-- numberals in /lowercase/.
romanNumeral'
  :: [RomanLiteral] -- ^ The given list of 'RomanLiteral' objects to convert to a Unicode equivalent.
  -> Text -- ^ A 'Text' object that contains a sequence of unicode characters that represents the 'RomanLiteral's.
romanNumeral' = _romanNumeral romanLiteral'

_romanNumber :: Integral i => ([RomanLiteral] -> a) -> RomanStyle -> Ligate -> i -> Maybe a
_romanNumber f r c = fmap f . toLiterals r c

-- | Convert a given number to a 'Text' wrapped in a 'Just' data constructor,
-- given the number can be converted to a Roman numeral, given it can be
-- represented. 'Nothing' in case it can not be represented. The number is
-- written in Roman numerals in /uppercase/.
romanNumber :: Integral i
  => RomanStyle -- ^ Specifies if the Numeral is 'Additive' or 'Subtractive' style.
  -> Ligate -- ^ Specifies if characters like @ⅠⅤ@ are joined to @Ⅳ@.
  -> i -- ^ The given number to convert.
  -> Maybe Text -- ^ A 'Text' if the given number can be specified with Roman
                -- numerals wrapped in a 'Just', 'Nothing' otherwise.
romanNumber = _romanNumber romanNumeral

-- | Convert a given number to a 'Text' wrapped in a 'Just' data constructor,
-- given the number can be converted to a Roman numeral, given it can be
-- represented. 'Nothing' in case it can not be represented. The number is
-- written in Roman numerals in /lowercase/.
romanNumber' :: Integral i
  => RomanStyle -- ^ Specifies if the Numeral is 'Additive' or 'Subtractive' style.
  -> Ligate -- ^ Specifies if characters like @ⅠⅤ@ are joined to @Ⅳ@.
  -> i -- ^ The given number to convert.
  -> Maybe Text -- ^ A 'Text' if the given number can be specified with Roman
                -- numerals wrapped in a 'Just', 'Nothing' otherwise.
romanNumber' = _romanNumber romanNumeral'
