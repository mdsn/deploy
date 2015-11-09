{-# LANGUAGE OverloadedStrings #-}

module Deploy.Core (
    ssh,
    command,
    Command(),
    AppName, Repository, VirtualEnv, CloneName,

    echo', clone, cd, ls,
    workon, mkvirtualenv, manage,
    verify, if', export', quit,
    run,

    module Turtle,
    module Turtle.Format,
    ) where

import Prelude hiding (FilePath)
import Turtle hiding (cd, ls)
import Turtle.Format


-- | Commands are just lists of Text, each representing a line of standard
-- input written to the server. Composition of commands through <> is just
-- appending of their lists of commands.

data Command = Command { cmd :: [Text] } deriving Show

instance Monoid Command where
    mempty = Command []
    mappend (Command a) (Command b) = Command (a ++ b)

command :: Text -> Command
command c = Command [c]


type AppName = Text
type Repository = Text
type VirtualEnv = Text
type CloneName = Text
type Host = Text


-- | Running commands

ssh :: MonadIO io => Host -> Shell Text -> io ExitCode
ssh host = shell $ format ("ssh -T "%s) host

run :: Host -> Command -> IO ExitCode
run host = ssh host . select . cmd


-- | Some basic building blocks

clone :: Repository -> Text -> Command
clone repo cloneDir = command $ format ("git clone git@github.com:"%s%".git "%s) repo cloneDir

workon :: Text -> Command
workon virtualenv = command $ format ("workon "%s) virtualenv

cd :: FilePath -> Command
cd path = command $ format ("cd "%fp) path

ls :: Command
ls = command "ls"

mkvirtualenv :: Text -> Command
mkvirtualenv venv = command $ format ("mkvirtualenv "%s) venv

manage :: Text -> Command
manage c = command $ format ("python manage.py "%s) c

if' :: Text -> Command -> Command
if' cond action = command (format ("if [ "%s%" ]; then") cond)
               <> action
               <> command "fi"

{- Run a Command and exit() on non-zero return code -}
verify :: Command -> Command
verify c = c
        <> command "rc=$?;"
        <> if' "$rc -ne 0" (command "exit $rc")

export' :: Text -> Text -> Command
export' var val = command $ format ("export "%s%"="%s) var val

echo' :: Text -> Command
echo' t = command $ format ("echo "%s) t

quit :: Int -> Command
quit n = command $ format ("exit "%d) n
