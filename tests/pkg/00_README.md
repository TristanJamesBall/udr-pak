## NOTE

The informix pakages that you can't see here ( too big for git ) are just pre-installed snapshots of the developer edition

To recreate:

- Install a new ediition of informix into tests/server
```
cd tests
tar --zst -cf [version].tar.zst server
```

( You can do scripted installs, but it's faster this way )