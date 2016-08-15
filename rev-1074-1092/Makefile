.PHONY: clean trim

default: farmanager-1074-1092-git trim

0000-1092.svn:
	svnadmin dump ../farmanager-mirror -q -r0:1092 > 0000-1092.svn

sdf_params = --quiet --drop-all-empty-revs --renumber-revs
enc.svn:         0000-1092.svn
	cat 0000-1092.svn | svndumpfilter $(sdf_params)  include "enc"         > enc.svn
addons.svn:      0000-1092.svn
	cat 0000-1092.svn | svndumpfilter $(sdf_params)  include "misc/addons" > addons.svn
docs.svn:        0000-1092.svn
	cat 0000-1092.svn | svndumpfilter $(sdf_params)  include "misc/docs"   > docs.svn
plugins.svn:     0000-1092.svn
	cat 0000-1092.svn | svndumpfilter $(sdf_params)  include "plugins"     > plugins.svn
unicode_far.svn: 0000-1092.svn
	cat 0000-1092.svn | svndumpfilter $(sdf_params)  include "unicode_far" > unicode_far.svn

enc-git:         enc.svn
	reposurgeon "verbose 1" "script enc.lift"         "prefer git" "rebuild enc-git"
addons-git:      addons.svn
	reposurgeon "verbose 1" "script addons.lift"      "prefer git" "rebuild addons-git"
docs-git:        docs.svn
	reposurgeon "verbose 1" "script docs.lift"        "prefer git" "rebuild docs-git"
plugins-git:     plugins.svn
	reposurgeon "verbose 1" "script plugins.lift"     "prefer git" "rebuild plugins-git"
unicode_far-git: unicode_far.svn
	reposurgeon "verbose 1" "script unicode_far.lift" "prefer git" "rebuild unicode_far-git"

misc-git: addons-git docs-git
	rm -fr misc-git
	git init misc-git
	git-stitch-repo addons-git:addons docs-git:docs | git -C misc-git fast-import
	git -C misc-git branch -m master-docs-git master
	git -C misc-git branch -d master-addons-git

.ONESHELL:
farmanager-1074-1092-git: enc-git misc-git plugins-git unicode_far-git
	rm -fr farmanager-1074-1092-git
	git init farmanager-1074-1092-git
	git-stitch-repo enc-git:enc misc-git:misc plugins-git:plugins unicode_far-git:unicode_far | git -C farmanager-1074-1092-git fast-import
	git -C farmanager-1074-1092-git branch -m master-unicode_far-git master
	git -C farmanager-1074-1092-git branch -d master-enc-git master-misc-git master-plugins-git
	cd farmanager-1074-1092-git
	git tag 180_b301 180_b301-unicode_far-git && git tag -d 180_b301-unicode_far-git
	git tag 180_b302 180_b302-unicode_far-git && git tag -d 180_b302-unicode_far-git
	git tag 180_b303 180_b303-unicode_far-git && git tag -d 180_b303-unicode_far-git
	git tag 180_b304 180_b304-unicode_far-git && git tag -d 180_b304-unicode_far-git

.ONESHELL:
trim: farmanager-1074-1092-git
	cd farmanager-1074-1092-git
	# Truncate the final history to include only the desired revisions
	git reset --hard
	git rev-parse master~13 >.git/info/grafts
	git filter-branch --tag-name-filter cat -- --all
	rm .git/info/grafts
	git gc

clean:
	rm -fr *.svn *-git
