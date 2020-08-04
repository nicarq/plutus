module Types where

import API (RunResult)
import Analytics (class IsEvent, defaultEvent)
import Blockly.Types (BlocklyState)
import Data.Either (Either)
import Data.Generic.Rep (class Generic)
import Data.Generic.Rep.Show (genericShow)
import Data.Json.JsonEither (JsonEither)
import Data.Lens (Lens', (^.))
import Data.Lens.Iso.Newtype (_Newtype)
import Data.Lens.Record (prop)
import Data.Maybe (Maybe(..))
import Data.Newtype (class Newtype)
import Data.Symbol (SProxy(..))
import Halogen (AttrName(..), ClassName)
import Halogen as H
import Halogen.Blockly (BlocklyMessage, BlocklyQuery)
import Halogen.Classes (activeClass)
import Halogen.HTML (IProp, attr)
import Halogen.Monaco (KeyBindings)
import Halogen.Monaco as Monaco
import Language.Haskell.Interpreter (InterpreterError, InterpreterResult)
import Language.Javascript.Interpreter as JS
import Network.RemoteData (RemoteData)
import Prelude (class Eq, class Show, Unit, eq, show, (<<<), ($))
import Servant.PureScript.Ajax (AjaxError)
import Simulation.Types as Simulation
import Wallet as Wallet

------------------------------------------------------------
data HQuery a
  = ReceiveWebsocketMessage String a

data Message
  = WebsocketMessage String

data HAction
  -- Haskell Editor
  = HaskellHandleEditorMessage Monaco.Message
  | JSHandleEditorMessage Monaco.Message
  | HaskellSelectEditorKeyBindings KeyBindings
  | JSSelectEditorKeyBindings KeyBindings
  | ShowBottomPanel Boolean
  -- haskell actions
  | CompileHaskellProgram
  | CompileJSProgram
  | ChangeView View
  | SendResultToSimulator
  | SendResultJSToSimulator
  | SendResultToBlockly
  | LoadHaskellScript String
  | LoadJSScript String
  -- Simulation Actions
  | HandleSimulationMessage Simulation.Message
  -- blockly
  | HandleBlocklyMessage BlocklyMessage
  -- Wallet Actions
  | HandleWalletMessage Wallet.Message

-- | Here we decide which top-level queries to track as GA events, and
-- how to classify them.
instance actionIsEvent :: IsEvent HAction where
  toEvent (HaskellHandleEditorMessage _) = Just $ defaultEvent "HaskellHandleEditorMessage"
  toEvent (JSHandleEditorMessage _) = Just $ defaultEvent "JSHandleEditorMessage"
  toEvent (HaskellSelectEditorKeyBindings _) = Just $ defaultEvent "HaskellSelectEditorKeyBindings"
  toEvent (JSSelectEditorKeyBindings _) = Just $ defaultEvent "JSSelectEditorKeyBindings"
  toEvent (HandleSimulationMessage action) = Just $ defaultEvent "HandleSimulationMessage"
  toEvent (HandleWalletMessage action) = Just $ defaultEvent "HandleWalletMessage"
  toEvent CompileHaskellProgram = Just $ defaultEvent "CompileHaskellProgram"
  toEvent CompileJSProgram = Just $ defaultEvent "CompileJSProgram"
  toEvent (ChangeView view) = Just $ (defaultEvent "View") { label = Just (show view) }
  toEvent (LoadHaskellScript script) = Just $ (defaultEvent "LoadScript") { label = Just script }
  toEvent (LoadJSScript script) = Just $ (defaultEvent "LoadJSScript") { label = Just script }
  toEvent (HandleBlocklyMessage _) = Just $ (defaultEvent "HandleBlocklyMessage") { category = Just "Blockly" }
  toEvent (ShowBottomPanel _) = Just $ defaultEvent "ShowBottomPanel"
  toEvent SendResultToSimulator = Just $ defaultEvent "SendResultToSimulator"
  toEvent SendResultJSToSimulator = Just $ defaultEvent "SendResultJSToSimulator"
  toEvent SendResultToBlockly = Just $ defaultEvent "SendResultToBlockly"

------------------------------------------------------------
type ChildSlots
  = ( haskellEditorSlot :: H.Slot Monaco.Query Monaco.Message Unit
    , jsEditorSlot :: H.Slot Monaco.Query Monaco.Message Unit
    , blocklySlot :: H.Slot BlocklyQuery BlocklyMessage Unit
    , simulationSlot :: H.Slot Simulation.Query Simulation.Message Unit
    , walletSlot :: H.Slot Wallet.Query Wallet.Message Unit
    )

_haskellEditorSlot :: SProxy "haskellEditorSlot"
_haskellEditorSlot = SProxy

_jsEditorSlot :: SProxy "jsEditorSlot"
_jsEditorSlot = SProxy

_blocklySlot :: SProxy "blocklySlot"
_blocklySlot = SProxy

_simulationSlot :: SProxy "simulationSlot"
_simulationSlot = SProxy

_walletSlot :: SProxy "walletSlot"
_walletSlot = SProxy

-----------------------------------------------------------
data View
  = HaskellEditor
  | JSEditor
  | Simulation
  | BlocklyEditor
  | WalletEmulator

derive instance eqView :: Eq View

derive instance genericView :: Generic View _

instance showView :: Show View where
  show = genericShow

newtype FrontendState
  = FrontendState
  { view :: View
  , compilationResult :: WebData (JsonEither InterpreterError (InterpreterResult RunResult))
  , jsCompilationResult :: Maybe (Either JS.CompilationError (JS.InterpreterResult String))
  , blocklyState :: Maybe BlocklyState
  , haskellEditorKeybindings :: KeyBindings
  , jsEditorKeybindings :: KeyBindings
  , activeHaskellDemo :: String
  , activeJSDemo :: String
  , showBottomPanel :: Boolean
  }

derive instance newtypeFrontendState :: Newtype FrontendState _

type WebData
  = RemoteData AjaxError

data MarloweError
  = MarloweError String

_view :: Lens' FrontendState View
_view = _Newtype <<< prop (SProxy :: SProxy "view")

_compilationResult :: Lens' FrontendState (WebData (JsonEither InterpreterError (InterpreterResult RunResult)))
_compilationResult = _Newtype <<< prop (SProxy :: SProxy "compilationResult")

_jsCompilationResult :: Lens' FrontendState (Maybe (Either JS.CompilationError (JS.InterpreterResult String)))
_jsCompilationResult = _Newtype <<< prop (SProxy :: SProxy "jsCompilationResult")

_blocklyState :: Lens' FrontendState (Maybe BlocklyState)
_blocklyState = _Newtype <<< prop (SProxy :: SProxy "blocklyState")

_haskellEditorKeybindings :: Lens' FrontendState KeyBindings
_haskellEditorKeybindings = _Newtype <<< prop (SProxy :: SProxy "haskellEditorKeybindings")

_jsEditorKeybindings :: Lens' FrontendState KeyBindings
_jsEditorKeybindings = _Newtype <<< prop (SProxy :: SProxy "jsEditorKeybindings")

_activeHaskellDemo :: Lens' FrontendState String
_activeHaskellDemo = _Newtype <<< prop (SProxy :: SProxy "activeHaskellDemo")

_activeJSDemo :: Lens' FrontendState String
_activeJSDemo = _Newtype <<< prop (SProxy :: SProxy "activeJSDemo")

_showBottomPanel :: Lens' FrontendState Boolean
_showBottomPanel = _Newtype <<< prop (SProxy :: SProxy "showBottomPanel")

-- editable
_timestamp ::
  forall s a.
  Lens' { timestamp :: a | s } a
_timestamp = prop (SProxy :: SProxy "timestamp")

_value :: forall s a. Lens' { value :: a | s } a
_value = prop (SProxy :: SProxy "value")

isActiveTab :: FrontendState -> View -> Array ClassName
isActiveTab state activeView = state ^. _view <<< (activeClass (eq activeView))

-- TODO: https://github.com/purescript-halogen/purescript-halogen/issues/682
bottomPanelHeight :: forall r i. Boolean -> IProp r i
bottomPanelHeight true = attr (AttrName "style") ""

bottomPanelHeight false = attr (AttrName "style") "height: 3.5rem"
