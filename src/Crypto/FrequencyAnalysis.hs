module Crypto.FrequencyAnalysis
    (
        computeWordCounts,
        relativeFreqs,
        scoreWith, 
        searchForCharKeyWith,
        maxCharWith,
        minCharWith,
    )
    where

import           Util.ByteManipulation
import           Util.Hexadecimal
import           Data.Maybe
import qualified Data.ByteString                  as BS
import qualified Data.ByteString.Char8            as BSC8
import qualified Data.Map.Strict                  as Map
import           Data.Word
import           Data.List (maximumBy, minimumBy)
import qualified Data.List                        as L (map)
import           Data.Char (chr, toUpper)



computeWordCounts :: Integral a => BS.ByteString -> Map.Map Word8 a
computeWordCounts bs = BS.foldl update Map.empty bs
    where
        update table key = case Map.lookup (upper key) table of
            Nothing  -> Map.insert (upper key) 1 table
            Just val -> Map.adjust (\val -> val+1) (upper key) table

        upper = c2w . toUpper . w2c


toFreqs :: (Integral a, Floating b, Ord b) => Map.Map Word8 a -> Map.Map Word8 b
toFreqs wmap = Map.map freq wmap
    where
        total = Map.foldl (\acc val -> acc + val) 0 wmap

        freq val = fromIntegral val / fromIntegral total


relativeFreqs :: (Floating a, Ord a) => BS.ByteString -> Map.Map Word8 a
relativeFreqs = toFreqs . computeWordCounts


scoreWith :: (Floating a, Ord a) => (Map.Map Word8 a -> a) -> BS.ByteString -> a
scoreWith scoreFunc = scoreFunc . relativeFreqs


searchForCharKeyWith :: (Floating a, Ord a) => ( (((Word8, BS.ByteString), a) -> ((Word8, BS.ByteString), a) -> Ordering) -> [((Word8, BS.ByteString), a)] -> ((Word8, BS.ByteString), a) )
                                            -> (BS.ByteString -> a)
                                            -> [Word8]
                                            -> BS.ByteString 
                                            -> ((Word8, BS.ByteString), a)
searchForCharKeyWith searchFunc scoreFunc charSet st = 
    searchFunc (\p1 p2 -> compare (snd p1) (snd p2) ) scores
        where
            scores = L.map (\ch -> ((ch, cipherText ch st), scoreFunc $ cipherText ch st)) charSet
            cipherText ch st = xorWithChar ch st


maxCharWith :: (Floating a, Ord a) => (BS.ByteString -> a)
                                      -> [Word8]
                                      -> BS.ByteString 
                                      -> ((Word8, BS.ByteString), a)
maxCharWith = searchForCharKeyWith maximumBy


minCharWith :: (Floating a, Ord a) => (BS.ByteString -> a)
                                      -> [Word8]
                                      -> BS.ByteString 
                                      -> ((Word8, BS.ByteString), a)
minCharWith = searchForCharKeyWith minimumBy


--totalVariationDistance :: (Floating a, Ord a) => Map.Map Word8 a -> Map.Map Word8 a -> a
--totalVariationDistance ps qs = 