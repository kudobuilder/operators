## Repository Build Process

The repository build process is a 2 step process.  First build the set of operators you wish to build. Then create the repository index file for that repository.

The "community" repository is the repository for all operators in the community and is a default location for all operator builds. The build process expects the following prerequisites:

1. kubectl-kudo is in the path
2. bash is the shell
3. you have online web access to the community repo during the build process.

## Step 1 Build Operators

The `./build-operator.sh` is a script within the github repo for building operators.  It has a number of conveniences based on conventions that have developed. Regardless of convention, a sure way to get a success build using the script is to provide the path to the operator.

`./build-operator.sh repository/mysql/operator/`

Another option is to provide the name of the operator assuming it is in "repository/{NAME}/operator" folder as in:

`./build-operator.sh mysql`

Another convention is to have a version number associated with the build using the convention of "repository/{NAME}/{VERSION}/operator"

`./build-operator.sh cassandra 3.11`

**NOTES:**
1. All builds will be under `build/repo` under the project
2. All builds will add to `build/repo`.  If you want to add more than 1 operator, run multiple operator builds before building the index.
3. There is no rebuild and if the operator already exists the build will fail.

## Step 2 Build Index

To build the index simple run `./build-community-repo.sh`

This will build a `index.yaml` file under `build/repo`

## Clean the build

`make clean` or `./clean-build.sh` will remove the `build/repo` folder.
