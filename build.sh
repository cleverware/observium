SCRIPT=$(readlink -f "$0")
BASEDIR=$(dirname $SCRIPT)
echo $BASEDIR
docker build --rm  -t cleverware/observium $BASEDIR

