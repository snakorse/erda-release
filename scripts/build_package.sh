cd "$(dirname "${BASH_SOURCE[0]}")"

rm -rf ./erda-actions

git clone https://github.com/erda-project/erda-actions.git

tar -cvzf ../package/erda-release.tar.gz ../../erda-release