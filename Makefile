# copies most rescent files from eplapp for updating to git.
SERVER=eplapp.library.ualberta.ca
USER=sirsi
REMOTE=~/Unicorn/Bincustom/
LOCAL=~/projects/diff/
APP=diff.pl

put: test
	scp ${LOCAL}${APP} ${USER}@${SERVER}:${REMOTE}
test: ${LOCAL}${APP}
	perl -c ${LOCAL}${APP}
