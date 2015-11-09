{-# LANGUAGE OverloadedStrings #-}

module Deploy where

import Prelude hiding (FilePath)
import Deploy.Core


-- | Directories


appBaseDir :: FilePath
appBaseDir = "~/webapps/"

appDir :: AppName -> FilePath
appDir a = fromText $ format ("~/webapps/"%s) a

projectDir :: AppName -> FilePath
projectDir a = fromText $ format (fp%"/"%s%"/"%s%"_project") appBaseDir a a

manageDir :: AppName -> FilePath
manageDir a = fromText $ format (fp%"/"%s) (projectDir a) a


-- | Subroutines


makeVirtualEnv :: VirtualEnv -> Command
makeVirtualEnv name = verify virtualenvExists
                   <> mkvirtualenv name
  where
    virtualenvExists :: Command
    virtualenvExists =
          command $ format ("! lsvirtualenv -b| grep -P '^"%s%"$'") name

cloneToApp :: Repository -> AppName -> Command
cloneToApp repo app = if' dirDoesntExist
                        (echo' "Application directory doesn't exist: nowhere to clone"
                      <> quit 1)
                   <> cd (appDir app)
                   <> clone repo cloneDir
  where
    dirDoesntExist = format ("! -d "%fp) (appDir app)
    cloneDir = format (s%"_project") app

installRequirements :: VirtualEnv -> AppName -> Command
installRequirements v a = workon v
                       <> cd (projectDir a)
                       <> if' "! -f requirements.txt"
                            (echo' "Missing requirements.txt file in $PWD"
                          <> quit 1)
                       <> command "pip install -r requirements.txt"

syncDb :: VirtualEnv -> AppName -> Command
syncDb v a = export' "DJANGO_CONFIGURATION" "Production"
          <> workon v
          <> cd (manageDir a)
          <> manage "syncdb --noinput"
          <> manage "migrate --fake"

collectStatic :: VirtualEnv -> AppName -> Command
collectStatic v a = export' "DJANGO_CONFIGURATION" "Production"
                 <> workon v
                 <> cd (manageDir a)
                 <> manage "collectstatic --noinput"

