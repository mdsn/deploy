# deploy
A small set of combinators to write lines of input through ssh

# installation
Run `stack build`.

# usage
Commands are built from lines of input to be written to the server. Use <> for
command composition.

Write new commands using the `command` function: 
```
    let which x = command $ format ("which "%s) x
```

Run a chain of commands with the `run` function, which takes a hostname to
connect to.

```
    > let c = which "python" <> cd "/etc" <> ls <> command "whoami"
    > run "hostname" c
```
