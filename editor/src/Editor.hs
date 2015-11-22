{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE RecordWildCards #-}
{-# LANGUAGE RecursiveDo #-}

module Main where

import Control.Monad
import Control.Monad.IO.Class
import Data.Maybe
import Reflex
import Reflex.Dom
import Unison.Dimensions (Width(..),X(..),Y(..))
import Unison.Term
import Unison.UI (mouseMove')
import qualified Data.Map as Map
import qualified Data.Set as Set
import qualified Reflex.Dynamic as Dynamic
import qualified Unison.DocView as DocView
import qualified Unison.Metadata as Metadata
import qualified Unison.Node as Node
import qualified Unison.Node.MemNode as MemNode
import qualified Unison.Note as Note
import qualified Unison.Paths as Paths
import qualified Unison.Reference as Reference
import qualified Unison.Signals as Signals
import qualified Unison.Term as Term
import qualified Unison.TermExplorer as TermExplorer
import qualified Unison.TermExplorer as TermExplorer
import qualified Unison.Type as Type
import qualified Unison.UI as UI
import qualified Unison.Views as Views

term = builtin "Vector.concatenate" `app`
         (vector (map num [11..15])) `app`
         (vector ([builtin "Number.plus" `app` num 1 `app` num 1, num 2, num 9]))

termDoc = Views.term Views.defaultSymbol term

keepWhen :: Reflex t => Behavior t Bool -> Event t a -> Event t a
keepWhen = gate

dropWhen :: Reflex t => Behavior t Bool -> Event t a -> Event t a
dropWhen b = keepWhen (not <$> b)

termEditor :: Term MemNode.V -> IO ()
termEditor term0 = mainWidget $ do
  node <- liftIO MemNode.make
  symbols0 <- (liftIO . Note.run . Node.metadatas node . Set.toList . Term.dependencies') term0
  keydown <- UI.windowKeydown
  rec
    openEvent <- pure $
      let
        events = leftmost
          [ void $ Signals.enter keydown
          , void $ ffilter (== 79) keydown -- [o]pen
          , void $ clickDoc ]
      in dropWhen isExplorerOpen events
    isExplorerOpen <- hold False $
      let f p = case p of Just (_, True) -> True; _ -> False
      in leftmost [ True <$ openEvent, f <$> keepWhen isExplorerOpen actions ]
    clickDoc <- switchPromptly never (maybe never (domEvent Click) <$> updated e)
    state <- holdDyn (TermExplorer.S symbols0 Nothing (Paths.Term term) [] 0) updatedState
    docs <- id $
      let
        f (TermExplorer.S{..}) = case overallTerm of
          Paths.Term term -> Views.termMd metadata term
          Paths.Type typ -> Views.typeMd metadata typ
          Paths.Var v -> Views.termMd metadata (Term.var v)
      in
        mapDyn f state
    terms <- holdDyn term0 (fmapMaybe (\TermExplorer.S{..} -> Paths.asTerm overallTerm) (updated state))
    (e, dims, path) <- elClass "div" "root" $ DocView.widgets (dropWhen isExplorerOpen keydown) (Width 400) docs
    info <- do
      infos <- combineDyn (\e p -> liftIO . Note.run $ Node.localInfo node e p) terms path
      dyn infos
    (state', actions) <- TermExplorer.make node (keepWhen isExplorerOpen keydown) info state
    updatedState <- pure $
      let
        -- todo - interpret advancement
        f (Just (a, advance)) = case a of
          TermExplorer.Replace p term -> do
            s <- sample (current state')
            pure $ s { TermExplorer.overallTerm = fromMaybe (TermExplorer.overallTerm s) $
                       Paths.modify (Paths.Term . const term) p (TermExplorer.overallTerm s) }
          _ -> error "todo: Eval + Step"
        f _ = sample (current state')
      in pushAlways f actions
  pure ()

main :: IO ()
main = termEditor term
