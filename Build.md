# Building Operator Packages and Repositories

The repository build process is a 2 step process. First build the set of operators you wish to build. Then create the repository index file for that repository.

The "community" repository is the repository for all operators in the community and is a default location for all operator builds. The build process expects the following prerequisites:

1. `kubectl-kudo` and `bash` are in the path
1. your working directory is the root of the checked out `operators` Git repository
1. you have online web access to the "community" repository during the build process.

## Step 1: Build Operators

`./build-operator.sh` is a script within the github repo for building operator packages. It has a number of conveniences based on conventions that have developed. Regardless of convention, a sure way to get a success build using the script is to provide the path to the operator.

`./build-operator.sh repository/mysql/operator/`

Another option is to provide the name of the operator assuming it is in the "repository/{NAME}/operator" folder as in:

`./build-operator.sh mysql`

Another convention is to have a version number associated with the build using the convention of "repository/{NAME}/{VERSION}/operator"

`./build-operator.sh cassandra 3.11`

**NOTES:**
1. Built artifacts will be put under `build/repo` in the current directory.
1. If you want to add more than 1 operator, build multiple operator packages before building the repository index.
3. There is no rebuild and if the operator already exists the build will fail.

## Step 2: Build Repository Index

To build the repository index simple run `./build-community-repo.sh` or `make index`.

This will build an `index.yaml` file under `build/repo`.

## Clean the build

`make clean` or `./clean-build.sh` will remove the `build/repo` folder.
