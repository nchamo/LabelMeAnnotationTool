#!/bin/bash
set -eo pipefail
__dirname=$(cd $(dirname "$0"); pwd -P)
cd "${__dirname}"
# Load default values
source .env
DEFAULT_PORT="$WO_PORT"
DEFAULT_HOST="$WO_HOST"
DEFAULT_MEDIA_DIR="$WO_MEDIA_DIR"
DEFAULT_ANNOTATIONS_DIR="$WO_ANNOTATIONS_DIR"

# Parse args for overrides
POSITIONAL=()
while [[ $# -gt 0 ]]
do
key="$1"

case $key in
    --port)
    export WO_PORT="$2"
    shift # past argument
    shift # past value
    ;;    
    --hostname)
    export WO_HOST="$2"
    shift # past argument
    shift # past value
    ;;
	--media-dir)
    export WO_MEDIA_DIR=$(realpath "$2")
    shift # past argument
    shift # past value
    ;;
  --annotations-dir)
    export WO_ANNOTATIONS_DIR=$(realpath "$2")
    shift # past argument
    shift # past value
    ;;  
    *)    # unknown option
    POSITIONAL+=("$1") # save it in an array for later
    shift # past argument
    ;;
esac
done
set -- "${POSITIONAL[@]}" # restore positional parameter

usage(){
  echo "Usage: $0 <command>"
  echo
  echo "This program helps to manage the setup/teardown of the docker containers for running LabelMe. We recommend that you read the full documentation of docker at https://docs.docker.com if you want to customize your setup."
  echo 
  echo "Command list:"
  echo "	start [options]		Start LabelMe"
  echo "	stop			Stop LabelMe"
  echo "	down			Stop and remove LabelMe's docker containers"
  echo "	rebuild			Rebuild all docker containers and perform cleanups"
  echo ""
  echo "Options:"
  echo "	--port	<port>	Set the port that WebODM should bind to (default: $DEFAULT_PORT)"
  echo "	--hostname	<hostname>	Set the hostname that LabelMe will be accessible from (default: $DEFAULT_HOST)"
  echo "	--media-dir	<path>	Path where processing results will be stored to (default: $DEFAULT_MEDIA_DIR (docker named volume))"
  echo "	--annotations-dir	<path>	Path where label results will be stored to (default: $DEFAULT_ANNOTATIONS_DIR (docker named volume))"
  exit
}

run(){
	echo $1
	eval $1
}

start(){
	echo ""
	echo "Using the following environment:"
	echo "================================"
	echo "Host: $WO_HOST"
	echo "Port: $WO_PORT"
	echo "Media directory: $WO_MEDIA_DIR"
  echo "Annotations directory: $WO_ANNOTATIONS_DIR"
	echo "================================"
	echo "Make sure to issue a $0 down if you decide to change the environment."
	echo ""

	command="docker-compose -f docker-compose.yml"
	run "$command start || $command up -d"
  docker exec labelme service apache2 restart
}

down(){
	run "docker-compose -f docker-compose.yml down --remove-orphans"
}

rebuild(){
	run "docker-compose down --remove-orphans"
	run "docker-compose -f docker-compose.yml -f docker-compose.build.yml build --no-cache"
	echo -e "\033[1mDone!\033[0m You can now start LabelMe by running $0 start"
}

if [[ $1 = "start" ]]; then
	start
elif [[ $1 = "stop" ]]; then
	echo "Stopping LabelMe..."
	run "docker-compose -f docker-compose.yml stop"
elif [[ $1 = "down" ]]; then
	echo "Tearing down LabelMe..."
	down
elif [[ $1 = "rebuild" ]]; then
	echo  "Rebuilding LabelMe..."
	rebuild
else
	usage
fi
