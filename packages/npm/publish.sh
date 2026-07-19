#!/bin/bash
# Usage: bash publish.sh --build-only --emit --skip-login

set -e # -x
dir=$(pwd)
bash_args="$@"
dist_dir="./dist"
# npm version patch --no-git-tag-version
package=$(echo "console.log(require(\"./package.json\").name)" | node)
version=$(echo "console.log(require(\"./package.json\").version)" | node)
cache_dir="./node_modules/.cache/${package}"

function check_argument {
    local value=$1
    for arg in $bash_args; do
        if [ "$arg" == "$value" ]; then
            return 0 # success
        fi
    done
    return 1 # failure
}

function echo_notice {
    local value=$1
    echo -e "\033[32m$value\033[0m"
}

export BUILD_VERSION=$version
echo_notice "$package@$version"
echo_notice "Package: $(pnpm --filter "${package}" exec pwd)"

if ! check_argument "--emit" || check_argument "--build-only"; then
    echo_notice "Notice: Current Version Will Not Publish To NPM"
fi

if check_argument "--emit" && ! check_argument "--skip-login"; then
    npm login --registry https://registry.npmjs.org/
fi

pnpm run --filter "${package}" build
pnpm run --filter "${package}" lint:ts
pnpm run --filter "${package}" test

if check_argument "--build-only"; then
    exit 0
fi

rm -rf $cache_dir
mkdir -p $cache_dir
cp -r $dist_dir $cache_dir
echo "\
  const fs = require('fs');
  const json = require('./package.json');
  const dep = json.dependencies || {};
  for (const [key, value] of Object.entries(dep)) {
    if (value.startsWith('workspace')) {
      const v = require(key + '/package.json').version;
      dep[key] = v;
    }
  }
  fs.writeFileSync('$cache_dir/package.json', JSON.stringify(json, null, 2));
" | node

cd $cache_dir
if check_argument "--emit"; then
    npm publish --registry=https://registry.npmjs.org/ --access public
else
    npm publish --registry=https://registry.npmjs.org/ --dry-run
fi
