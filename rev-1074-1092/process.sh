#!/bin/sh
set -e

svnadmin dump ../farmanager-mirror -r0:1092 > 0000-1092.svn

sdf_params="--quiet --drop-all-empty-revs --renumber-revs"

echo 'Dumping enc';          cat 0000-1092.svn | svndumpfilter $sdf_params  include "enc"         > enc.svn
echo 'Dumping misc/addons';  cat 0000-1092.svn | svndumpfilter $sdf_params  include "misc/addons" > addons.svn
echo 'Dumping misc/docs';    cat 0000-1092.svn | svndumpfilter $sdf_params  include "misc/docs"   > docs.svn
echo 'Dumping plugins';      cat 0000-1092.svn | svndumpfilter $sdf_params  include "plugins"     > plugins.svn
# Exclude "test" folder from the conversion
echo 'Dumping unicode_far';  cat 0000-1092.svn | svndumpfilter $sdf_params  include "unicode_far" > unicode_far.svn

reposurgeon "verbose 1" "script farmanager-1074-1092.lift"
rm -f *.svn

git init misc
cd misc
git-stitch-repo ../addons ../docs | git fast-import
git branch -m master-docs master
git branch -d master-addons
cd ..
rm -fr addons docs

rm -fr farmanager-1074-1092-git
git init farmanager-1074-1092-git
cd farmanager-1074-1092-git
git-stitch-repo ../enc ../misc ../plugins ../unicode_far | git fast-import
git branch -m master-unicode_far master
git branch -d master-enc master-misc master-plugins
git tag 180_b301 180_b301-unicode_far && git tag -d 180_b301-unicode_far
git tag 180_b302 180_b302-unicode_far && git tag -d 180_b302-unicode_far
git tag 180_b303 180_b303-unicode_far && git tag -d 180_b303-unicode_far
git tag 180_b304 180_b304-unicode_far && git tag -d 180_b304-unicode_far
cd ..
rm -fr enc misc plugins unicode_far

# Truncate the final history to include only the desired revisions
cd farmanager-1074-1092-git
git reset --hard
git rev-parse master~13 >.git/info/grafts
git filter-branch --tag-name-filter cat -- --all
rm .git/info/grafts
git gc
cd ..
