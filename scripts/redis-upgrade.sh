#!/usr/bin/env bash

parseparams()
{
  while getopts "hy" opt; do
    case "${opt}" in
      y)
        Y=true
        ;;
      *)
        usage
        ;;
    esac
  done
  shift $((OPTIND-1))
}

config()
{
  YES_ALL=${Y:-false}
  if [ "$(whoami)" = "root" ]
  then
    echo "It is not recommended to run this script as root. As a normal user, elevation will be prompted if needed."
    [[ "$YES_ALL" = "true" ]] && confirm="y" || read -rp "Continue anyway? (Y/n) " confirm </dev/tty
    if [[ "$confirm" = "n" ]]; then exit 1; fi
  else
    if ! groups | grep docker; then
      echo "Please add your current user to the docker group."
      echo "You can run the following as root: \"usermod -aG docker $(whoami)\", then logout and login again"
      echo "current user is not allowed to use docker, exiting..."
      exit 1
    fi
  fi
  FM_PATH=$(pwd)
  TYPE="NOT-FOUND"
  [[ "$YES_ALL" = "true" ]] && confirm="y" || read -rp "Is Fab-manager installed at \"$FM_PATH\"? (y/N) " confirm </dev/tty
  if [ "$confirm" = "y" ]; then
    test_docker_compose
    if [[ "$TYPE" = "NOT-FOUND" ]]
    then
      echo "Redis was not found on the current system, exiting..."
      exit 2
    fi
  else
    echo "Please run this script from the Fab-manager's installation folder"
    exit 1
  fi
}

test_docker_compose()
{
  if [[ -f "$FM_PATH/docker-compose.yml" ]]
  then
    docker-compose ps | grep redis
    if [[ $? = 0 ]]
    then
      TYPE="DOCKER-COMPOSE"
    fi
  fi
}

yq() {
  docker run --rm -i -v "${FM_PATH}:/workdir" mikefarah/yq:4 "$@"
}


docker_down()
{
  docker-compose down
}

proceed_upgrade()
{
  yq -i eval '.services.redis.image = "redis:6-alpine"' docker-compose.yml
}


docker_up()
{
  docker-compose pull redis
  docker-compose up -d
}

usage()
{
  printf "Usage: %s [OPTIONS]
Options:
  -h                 Print this message and quit
  -y                 Answer yes to all questions\n" "$(basename "$0")" 1>&2
  exit 1
}

function trap_ctrlc()
{
  echo "Ctrl^C, exiting..."
  exit 2
}

upgrade_redis()
{
  parseparams "$@"
  config
  [[ "$YES_ALL" = "true" ]] && confirm="y" || read -rp "Continue with upgrading? (y/N) " confirm </dev/tty
  if [[ "$confirm" = "y" ]]; then
    trap "trap_ctrlc" 2 # SIGINT
    docker_down
    proceed_upgrade
    docker_up
  fi
}

upgrade_redis "$@"
