#!/usr/bin/env bash

parseparams()
{
  COMMANDS=()
  SCRIPTS=()
  ENVIRONMENTS=()
  while getopts "hys:c:e:" opt; do
    case "${opt}" in
      y)
        Y=true
        ;;
      s)
        SCRIPTS+=("$OPTARG")
        ;;
      c)
        COMMANDS+=("$OPTARG")
        ;;
      e)
        ENVIRONMENTS+=("$OPTARG")
        ;;
      *)
        usage
        ;;
    esac
  done
  shift $((OPTIND-1))
}

yq() {
  docker run --rm -i -v "${PWD}:/workdir" mikefarah/yq:4 "$@"
}

jq() {
  docker run --rm -i -v "${PWD}:/data" imega/jq "$@"
}

config()
{
  echo -ne "Checking user... "
  if [[ "$(whoami)" != "root" ]] && ! groups | grep docker
  then
      echo "Please add your current user to the docker group OR run this script as root."
      echo "current user is not allowed to use docker, exiting..."
      exit 1
  fi
  echo -e "Checking installation..."
  if [ ! -f "docker-compose.yml" ]; then
    echo -e "\e[91m[ ❌ ] docker-compose.yml was not found in ${PWD}. Please run this script from the Fab-manager's installation folder. Exiting... \e[39m"
    exit 1
  fi

  SERVICE="$(yq eval '.services.*.image | select(. == "sleede/fab-manager*") | path | .[-2]' docker-compose.yml)"
  YES_ALL=${Y:-false}
  # COMMANDS, SCRIPTS and ENVIRONMENTS are set by parseparams

  if [ -z "${SERVICE}" ]; then
    echo -e "\e[91m[ ❌ ] The service name was not determined. Please check your docker-compose.yml file. Exiting... \e[39m"
    exit 1
  fi
}

# compare versions utilities
# https://stackoverflow.com/a/4024263/1039377
verlte() {
    [  "$1" = "$(echo -e "$1\n$2" | sort -V | head -n1)" ]
}
verlt() {
    [ "$1" = "$2" ] && return 1 || verlte "$1" "$2"
}

version_error()
{
  printf "\n\n\e[91m[ ❌ ] You are running Fab-manager version %s\n\e[39m" "${VERSION:-undetermined}"
  printf "You must upgrade Fab-manager to %s first.\nPlease refer to https://github.com/sleede/fab-manager/blob/master/doc/production_readme.md#update-fab-manager for instructions\n" "$1" 1>&2
  exit 3
}

version_check()
{
  VERSION=$(docker-compose exec -T "$SERVICE" cat .fabmanager-version 2>/dev/null)
  if [[ $? = 1 ]]; then
    VERSION=$(docker-compose exec -T "$SERVICE" cat package.json | jq -r '.version')
  fi

  if verlt "$VERSION" 2.8.3; then
    version_error "v2.8.3"
  elif verlt "$VERSION" 3.1.2; then
    version_error "v3.1.2"
  elif verlt "$VERSION" 4.0.4; then
    version_error "v4.0.4"
  elif verlt "$VERSION" 4.4.6; then
    version_error "v4.4.6"
  fi
}

add_environments()
{
  for ENV in "${ENVIRONMENTS[@]}"; do
    if [[ "$ENV" =~ ^[A-Z0-9_]+=.*$ ]]; then
      printf "\e[91m::\e[0m \e[1mInserting variable %s..\e[0m.\n" "$ENV"
      printf "# added on %s\n%s\n" "$(date +%Y-%m-%d\ %R)" "$ENV" >> "config/env"
    else
      printf "\e[93m[ ⚠ ] Ignoring invalid option: -e %s.\e[39m\n Given value is not valid environment variable, please see https://huit.re/environment-doc\n" "$ENV"
    fi
  done
}

clean_env_file()
{
  # docker run --env-file does not support whitespaces in the environment variables so we must clean the file
  sed -ri 's/^([A-Z0-9_]+)\s*=\s*(.*)$/\1=\2/g' ./config/env
}

compile_assets()
{
  IMAGE=$(yq eval '.services.*.image | select(. == "sleede/fab-manager*")' docker-compose.yml)
  mapfile -t COMPOSE_ENVS < <(yq eval ".services.$SERVICE.environment" docker-compose.yml)
  ENV_ARGS=$(for i in "${COMPOSE_ENVS[@]}"; do sed 's/: /=/g;s/^/-e /g' <<< "$i"; done)
  PG_ID=$(docker-compose ps -q postgres)
  if [[ "$PG_ID" = "" ]]; then
    printf "\e[91m[ ❌ ] PostgreSQL container is not running, unable to compile the assets\e[39m\nExiting..."
    exit 1
  fi
  PG_NET_ID=$(docker inspect "$PG_ID" -f "{{json .NetworkSettings.Networks }}" | jq -r '.[] .NetworkID')
  clean_env_file
  # shellcheck disable=SC2068
  docker run --rm --env-file ./config/env ${ENV_ARGS[@]} --link "$PG_ID" --net "$PG_NET_ID" -v "${PWD}/public/new_packs:/usr/src/app/public/packs" "$IMAGE" bundle exec rake assets:precompile
  docker-compose down
  rm -rf public/packs
  mv public/new_packs public/packs
}

upgrade()
{
  [[ "$YES_ALL" = "true" ]] && confirm="y" || read -rp "[91m::[0m [1mProceed with the upgrade?[0m (Y/n) " confirm </dev/tty
  if [[ "$confirm" = "n" ]]; then exit 2; fi

  add_environments
  if ! docker-compose pull "$SERVICE"; then
    printf "\e[91m[ ❌ ] An error occurred, detected service name: %s\e[39m\nExiting..." "$SERVICE"
    exit 1
  fi
  BRANCH='master'
  if yq eval '.services.*.image | select(. == "sleede/fab-manager*")' docker-compose.yml | grep -q ':dev'; then BRANCH='dev'; fi
  for SCRIPT in "${SCRIPTS[@]}"; do
    printf "\e[91m::\e[0m \e[1mRunning script %s from branch %s...\e[0m\n" "$SCRIPT" "$BRANCH"
    if [[ "$YES_ALL" = "true" ]]; then
      \curl -sSL "https://raw.githubusercontent.com/sleede/fab-manager/$BRANCH/scripts/$SCRIPT.sh" | bash -s -- -y
    else
      \curl -sSL "https://raw.githubusercontent.com/sleede/fab-manager/$BRANCH/scripts/$SCRIPT.sh" | bash
    fi
    # shellcheck disable=SC2181
    if [[ $? != 0 ]]; then
      printf "\e[93m[ ⚠ ] Something may have went wrong while running \"%s\", please check the logs above...\e[39m\n" "$SCRIPT"
      [[ "$YES_ALL" = "true" ]] && confirm="y" || read -rp "[91m::[0m [1mIgnore and continue?[0m (Y/n) " confirm </dev/tty
      if [[ "$confirm" = "n" ]]; then exit 4; fi
    fi
  done
  compile_assets
  if ! docker-compose run --rm "$SERVICE" bundle exec rake db:migrate; then
    printf "\e[91m[ ❌ ] Something went wrong while migrating the database, please check the logs above.\e[39m\nExiting...\n"
    exit 4
  fi
  for COMMAND in "${COMMANDS[@]}"; do
    printf "\e[91m::\e[0m \e[1mRunning command %s...\e[0m\n" "$COMMAND"
    if ! docker-compose run --rm "$SERVICE" bundle exec "$COMMAND"; then
      printf "\e[91m[ ❌ ] Something went wrong while running \"%s\", please check the logs above.\e[39m\nExiting...\n" "$COMMAND"
      exit 4
    fi
  done
  docker-compose up -d
  docker ps
}

clean()
{
  echo -e "\e[91m::\e[0m \e[1mCurrent disk usage:\e[0m"
  df -h /
  [[ "$YES_ALL" = "true" ]] && confirm="y" || read -rp "[91m::[0m [1mClean previous docker images?[0m (y/N) " confirm </dev/tty
  if [[ "$confirm" == "y" ]]; then
    /usr/bin/docker image prune -f
  fi
}

usage()
{
  printf "Usage: %s [OPTIONS]
Options:
  -h                 Print this message and quit
  -y                 Answer yes to all questions
  -c <string>        Provides additional upgrade command, run in the context of the app (TODO DEPLOY)
  -s <string>        Executes a remote script (TODO DEPOY)
  -e <string>        Adds the environment variable to config/env\n" "$(basename "$0")" 1>&2
  exit 1
}

function trap_ctrlc()
{
  echo "Ctrl^C, exiting..."
  exit 2
}

proceed()
{
  trap "trap_ctrlc" 2 # SIGINT
  parseparams "$@"
  config
  version_check
  upgrade
  clean
}

proceed "$@"
