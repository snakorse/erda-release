cd "$(dirname "${BASH_SOURCE[0]}")"


rm -rf package
mkdir package

rm -rf erda/scripts/erda-actions
git clone https://github.com/erda-project/erda-actions.git erda/scripts/erda-actions
rm -rf erda/scripts/erda-actions/.git

rm -rf erda/scripts/erda-addons
git clone https://github.com/erda-project/erda-addons.git erda/scripts/erda-addons
rm -rf erda/scripts/erda-addons/.git

if [[ -z $ERDA_VERSION ]]; then
    echo "ERDA_VERSION is empty"
    exit
fi

echo "${ERDA_VERSION}" > erda/VERSION

if [[ -z $ERDA_OS_SYSTEM ]]; then
    echo "ERDA_OS_SYSTEM is empty"
    exit
fi

rm -rf erda/How-to-install-Erda.md
rm -rf erda/How-to-install-Erda-zh.md
wget https://raw.githubusercontent.com/erda-project/erda/v${ERDA_VERSION}/docs/guides/deploy/How-to-install-Erda.md -O erda/How-to-install-Erda.md
wget https://raw.githubusercontent.com/erda-project/erda/v${ERDA_VERSION}/docs/guides/deploy/How-to-install-Erda-zh.md -O erda/How-to-install-Erda-zh.md

if [[ $ERDA_OS_SYSTEM == "linux" ]]; then
    tar -cvzf package/erda-${ERDA_OS_SYSTEM}.tar.gz erda/
fi

if [[ $ERDA_OS_SYSTEM == "windows" ]]; then
    zip -r package/erda-${ERDA_OS_SYSTEM}.zip erda/
fi
