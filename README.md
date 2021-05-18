# Erda Release Tools

#### Release Package

1. Git clone the repo on your machine

   ```shell
   git clone https://github.com/erda-project/erda-release.git
   ```


2. Change directory to the erda-release folder

   ```shell
    cd erda-release
   ```

3. export ERDA_VERSION like 1.0,1.1,2.0, you can find the Erda verion list on [here](https://github.com/erda-project/erda/branches/all).
   
   ```shell
   # For example, if you find a branch name is release/1.0, you should set 1.0 to the ERDA_VERSION env
   export ERDA_VERSION=
   ```


4. Package the tarball

   ```shell
    bash scripts/build_package.sh
   ```

