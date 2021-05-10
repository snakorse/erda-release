cd "$(dirname "${BASH_SOURCE[0]}")"

rm -rf ./erda-actions

rm -rf ../package

mkdir ../package

git clone https://github.com/erda-project/erda-actions.git

git clone https://github.com/erda-project/erda-addons.git

tar -cvzf ../package/erda-release.tar.gz ../../erda-release