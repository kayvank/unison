{-# LANGUAGE DerivingVia #-}

module U.Codebase.Sqlite.LocalIds where

import Data.Bifoldable (Bifoldable (bifoldMap))
import Data.Bifunctor (Bifunctor (bimap))
import Data.Bitraversable (Bitraversable (bitraverse))
import Data.Bits (Bits)
import Data.Vector (Vector)
import Data.Word (Word64)
import U.Codebase.Sqlite.DbId

-- | A mapping between index ids that are local to an object and the ids in the database
data LocalIds' t h = LocalIds
  { textLookup :: Vector t,
    defnLookup :: Vector h
  }

type LocalIds = LocalIds' TextId ObjectId

type WatchLocalIds = LocalIds' TextId HashId

-- | represents an index into a textLookup
newtype LocalTextId = LocalTextId Word64 deriving (Eq, Ord, Num, Real, Enum, Integral, Bits) via Word64

-- | represents an index into a defnLookup
newtype LocalDefnId = LocalDefnId Word64 deriving (Eq, Ord, Num, Real, Enum, Integral, Bits) via Word64

newtype LocalHashId = LocalHashId Word64 deriving (Eq, Ord, Num, Real, Enum, Integral, Bits) via Word64

newtype LocalPatchObjectId = LocalPatchObjectId Word64 deriving (Eq, Ord, Num, Real, Enum, Integral, Bits) via Word64
newtype LocalBranchChildId = LocalBranchChildId Word64 deriving (Eq, Ord, Num, Real, Enum, Integral, Bits) via Word64

instance Bitraversable LocalIds' where
  bitraverse f g (LocalIds t d) = LocalIds <$> traverse f t <*> traverse g d

instance Bifoldable LocalIds' where
  bifoldMap f g (LocalIds t d) = foldMap f t <> foldMap g d

instance Bifunctor LocalIds' where
  bimap f g (LocalIds t d) = LocalIds (f <$> t) (g <$> d)
