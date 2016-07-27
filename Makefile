# Makefile for farmanager conversion using reposurgeon
#
# Steps to using this:
# 1. Make sure reposurgeon and repotool are on your $PATH.
# 2. For svn, set REMOTE_URL to point at the remote repository
#    you want to convert.
# 3. For cvs, set CVS_HOST to the repo hostname and CVS_MODULE to the module,
#    then uncomment the line that builds REMOTE_URL 
#    Note: for CVS hosts other than Sourceforge or Savannah you will need to 
#    include the path to the CVS modules directory after the hostname.
# 4. Set any required read options, such as --user-ignores or --nobranch,
#    by setting READ_OPTIONS.
# 5. Run 'make stubmap' to create a stub author map.
# 6. (Optional) set REPOSURGEON to point at a faster cython build of the tool.
# 7. Run 'make' to build a converted repository.
#
# The reason both first- and second-stage stream files are generated is that,
# especially with Subversion, making the first-stage stream file is often
# painfully slow. By splitting the process, we lower the overhead of
# experiments with the lift script.
#
# For a production-quality conversion you will need to edit the map
# file and the lift script.  During the process you can set EXTRAS to
# name extra metadata such as a comments mailbox.
#
# Afterwards, you can use the headcompare and tagscompare productions
# to check your work.
#

EXTRAS = 
REMOTE_URL = http://svn.code.sf.net/p/farmanager/code/
#REMOTE_URL = https://farmanager.googlecode.com/svn/
CVS_HOST = cvs.sourceforge.net
#CVS_HOST = cvs.savannah.gnu.org
CVS_MODULE = farmanager
#REMOTE_URL = cvs://$(CVS_HOST)/farmanager#$(CVS_MODULE)
READ_OPTIONS =
VERBOSITY = "verbose 1"
REPOSURGEON = reposurgeon

# Configuration ends here

.PHONY: local-clobber remote-clobber gitk gc compare clean dist stubmap
# Tell make not to auto-remove tag directories, because it only tries rm 
# and hence fails
.PRECIOUS: farmanager-%-checkout farmanager-%-git

default: farmanager-git

# Build the converted repo from the second-stage fast-import stream
farmanager-git: farmanager.fi
	rm -fr farmanager-git; $(REPOSURGEON) "read <farmanager.fi" "prefer git" "rebuild farmanager-git"

# Build the second-stage fast-import stream from the first-stage stream dump
farmanager.fi: farmanager.svn farmanager.opts farmanager.lift farmanager.map $(EXTRAS)
	$(REPOSURGEON) $(VERBOSITY) "script farmanager.opts" "read $(READ_OPTIONS) <farmanager.svn" "authors read <farmanager.map" "sourcetype svn" "prefer git" "script farmanager.lift" "legacy write >farmanager.fo" "write >farmanager.fi"

# Build the first-stage stream dump from the local mirror
farmanager.svn: farmanager-mirror
	repotool mirror farmanager-mirror
	(cd farmanager-mirror/ >/dev/null; repotool export) >farmanager.svn

# Build a local mirror of the remote repository
farmanager-mirror:
	repotool mirror $(REMOTE_URL) farmanager-mirror

# Make a local checkout of the source mirror for inspection
farmanager-checkout: farmanager-mirror
	cd farmanager-mirror >/dev/null; repotool checkout ../farmanager-checkout

# Make a local checkout of the source mirror for inspection at a specific tag
farmanager-%-checkout: farmanager-mirror
	cd farmanager-mirror >/dev/null; repotool checkout ../farmanager-$*-checkout $*

# Force rebuild of first-stage stream from the local mirror on the next make
local-clobber: clean
	rm -fr farmanager.fi farmanager-git *~ .rs* farmanager-conversion.tar.gz farmanager-*-git

# Force full rebuild from the remote repo on the next make.
remote-clobber: local-clobber
	rm -fr farmanager.svn farmanager-mirror farmanager-checkout farmanager-*-checkout

# Get the (empty) state of the author mapping from the first-stage stream
stubmap: farmanager.svn
	$(REPOSURGEON) "read <farmanager.svn" "authors write >farmanager.map"

# Compare the histories of the unconverted and converted repositories at head
# and all tags.
EXCLUDE = -x CVS -x .svn -x .git
EXCLUDE += -x .svnignore -x .gitignore
headcompare:
	repotool compare $(EXCLUDE) farmanager-checkout farmanager-git
tagscompare:
	repotool compare-tags $(EXCLUDE) farmanager-checkout farmanager-git

# General cleanup and utility
clean:
	rm -fr *~ .rs* farmanager-conversion.tar.gz *.svn *.fi *.fo

# Bundle up the conversion metadata for shipping
SOURCES = Makefile farmanager.lift farmanager.map $(EXTRAS)
farmanager-conversion.tar.gz: $(SOURCES)
	tar --dereference --transform 's:^:farmanager-conversion/:' -czvf farmanager-conversion.tar.gz $(SOURCES)

dist: farmanager-conversion.tar.gz

#
# The following productions are git-specific
#

# Browse the generated git repository
gitk: farmanager-git
	cd farmanager-git; gitk --all

# Run a garbage-collect on the generated git repository.  Import doesn't.
# This repack call is the active part of gc --aggressive.  This call is
# tuned for very large repositories.
gc: farmanager-git
	cd farmanager-git; time git -c pack.threads=1 repack -AdF --window=1250 --depth=250
