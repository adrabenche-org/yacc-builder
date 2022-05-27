# What
So, in a nutshell, you **only** need this Dockerfile to have any version of the `cardano-cli` built by yourself and, of course, customize any build parameter modifying the Dockerfile. 

Also set up the `cardano-cli` command as the entrypoint.

## Arguments
On this table you will find the build arguments. You can send it using the `--build-arg key=value` pair. Any doubt, you can find more information about this on the Docker documentation [here]().

| Argument Key| Type |Argument default value |What it is|
|---|---|---|---|
|GIT_NODE_REV| ARG| Last tagged version| This value specify based on which tag the Docker image will be built. For instance, if you want the *cardano-cli* version *1.34.1* then the value will be `1.34.1`.

## Examples
For all the example, we are asuming you already cloned and accessed the repository folder.

* Build a docker imager based on the last tagged version of the cardano node's [github repository](https://github.com/input-output-hk/cardano-node/tags):
```bash
$ sudo docker build -t cardano-cli:latest .
```
* Build a docker image based on version `1.34.0`:
```bash
sudo docker build -t cardano-cli:1.34.0 . --build-arg GIT_NODE_REV=1.34.0
```
* Find the `cardano-cli` version built:
```bash
 sudo docker run --rm cardano-cli:latest --version
```
The output will be version and GH revision at the time being, .
```
cardano-cli 1.33.0 - linux-x86_64 - ghc-8.10
git rev d5345054750de7b659a08de92b004de717a376c0
```

# About versions

The release numbers match as follows:

* First three numbers matches the `cardano-cli` version
* Last number match the `yacc-builder` release.

So, for instance `1.34.0.1` means:

* `1.34.0` is the `cardano-node` release version.
* `1` is the `yacc-builder` release version.

Then, next release of `yacc-builder` for cardano-node `1.34.0` will be `1.34.0.2`.