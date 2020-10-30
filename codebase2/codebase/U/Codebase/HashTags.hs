module U.Codebase.HashTags where

import U.Util.Hash (Hash)

newtype BranchHash = BranchHash { unBranchHash :: Hash } deriving (Eq, Ord, Show)

newtype CausalHash = CausalHash { unCausalHash :: Hash } deriving (Eq, Ord, Show)

newtype EditHash = EditHash { unEditHash :: Hash } deriving (Eq, Ord, Show)

newtype PatchHash = PatchHash { unPatchHash :: Hash } deriving (Eq, Ord, Show)
