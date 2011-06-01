{-# LANGUAGE DeriveDataTypeable #-}

-- |
-- Module:      Data.Configurator.Types.Internal
-- Copyright:   (c) 2011 MailRank, Inc.
-- License:     BSD3
-- Maintainer:  Bryan O'Sullivan <bos@mailrank.com>
-- Stability:   experimental
-- Portability: portable
--
-- Types for working with configuration files.

module Data.Configurator.Types.Internal
    (
      Config(..)
    , Configured(..)
    , AutoConfig(..)
    , Name
    , Value(..)
    , Binding
    , Path
    , Directive(..)
    , ConfigError(..)
    , Interpolate(..)
    ) where

import Control.Exception
import Data.Data (Data)
import Data.IORef (IORef)
import Data.Text (Text)
import Data.Typeable (Typeable)
import Prelude hiding (lookup)
import qualified Data.HashMap.Lazy as H

-- | Configuration data.
data Config = Config {
      cfgPaths :: [Path]
    -- ^ The files from which the 'Config' was loaded.
    , cfgMap :: IORef (H.HashMap Name Value)
    }

-- | This class represents types that can be automatically and safely
-- converted /from/ a 'Value' /to/ a destination type.  If conversion
-- fails because the types are not compatible, 'Nothing' is returned.
--
-- For an example of compatibility, a 'Value' of 'Bool' 'True' cannot
-- be 'convert'ed to an 'Int'.
class Configured a where
    convert :: Value -> Maybe a

-- | An error occurred while processing a configuration file.
data ConfigError = ParseError FilePath String
                   deriving (Show, Typeable)

-- | Directions for automatically reloading 'Config' data.
data AutoConfig = AutoConfig {
      interval :: Int
    -- ^ Interval (in seconds) at which to check for updates to config
    -- files.  The smallest allowed interval is one second.
    , onError :: SomeException -> IO ()
    -- ^ Action invoked when an attempt to reload a 'Config' fails.
    -- If this action rethrows its exception or throws a new
    -- exception, the modification checking thread will be killed.
    } deriving (Typeable)

instance Show AutoConfig where
    show c = "AutoConfig {interval = " ++ show (interval c) ++ "}"

instance Exception ConfigError

-- | The name of a 'Config' value.
type Name = Text

-- | A packed 'FilePath'.
type Path = Text

-- | A name-value binding.
type Binding = (Name,Value)

-- | A directive in a configuration file.
data Directive = Import Path
               | Bind Name Value
               | Group Name [Directive]
                 deriving (Eq, Show, Typeable, Data)

-- | A value in a 'Config'.
data Value = Bool Bool
           -- ^ A Boolean. Represented in a configuration file as @on@
           -- or @off@, @true@ or @false@ (case sensitive).
           | String Text
           -- ^ A Unicode string.  Represented in a configuration file
           -- as text surrounded by double quotes.
           --
           -- Escape sequences:
           --
           -- * @\\n@ - newline
           --
           -- * @\\r@ - carriage return
           --
           -- * @\\t@ - horizontal tab
           --
           -- * @\\\\@ - backslash
           --
           -- * @\\\"@ - quotes
           --
           -- * @\\u@/xxxx/ - Unicode character, encoded as four
           --   hexadecimal digits
           --
           -- * @\\u@/xxxx/@\\u@/xxxx/ - Unicode character (as two
           --   UTF-16 surrogates)
           | Number Int
           -- ^ Integer.
           | List [Value]
           -- ^ Heterogeneous list.  Represented in a configuration
           -- file as an opening square bracket \"@[@\", followed by a
           -- comma-separated series of values, ending with a closing
           -- square bracket \"@]@\".
             deriving (Eq, Show, Typeable, Data)

-- | An interpolation directive.
data Interpolate = Literal Text
                 | Interpolate Text
                   deriving (Eq, Show)
