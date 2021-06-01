cd "$(dirname "${BASH_SOURCE[0]}")"


rm -rf package
mkdir package

rm -rf ./erda/scripts/erda-actions
git clone https://github.com/erda-project/erda-actions.git ./erda/scripts/

rm -rf ./erda/scripts/erda-addons
git clone https://github.com/erda-project/erda-addons.git ./erda/scripts/

if [[ -z $ERDA_VERSION ]]; then
    echo "ERDA_VERSION is empty"
    exit
fi

wget https://raw.githubusercontent.com/erda-project/erda/release/${ERDA_VERSION}/docs/guides/deploy/How-to-install-the-Erda.md -O ./erda/How-to-install-the-Erda.md

tar -cvzf package/erda-${ERDA_OS_SYSTEM}.tar.gz erda/
