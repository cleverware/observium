set -x
DIRNAME=$( dirname "$(readlink -f -- "$0")" )
#SCRIPT=$(readlink $0)
#DIRNAME= $(dirname $SCRIPT)
$DIRNAME/remove.sh
$DIRNAME/build.sh
$DIRNAME/start.sh
