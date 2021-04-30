#!/usr/bin/env bash

yq() {
  docker run --rm -i -v "${NGINX_PATH}:/workdir" mikefarah/yq:4 "$@"
}

config()
{
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
  NGINX_PATH=$(pwd)
  TYPE="NOT-FOUND"
  [[ "$YES_ALL" = "true" ]] && confirm="y" || read -rp "Is Fab-manager installed at \"$NGINX_PATH\"? (y/N) " confirm </dev/tty
  if [ "$confirm" = "y" ]; then
    test_docker_compose
    while [[ "$TYPE" = "NOT-FOUND" ]]
    do
      echo "nginx was not found at the current path, please specify the nginx installation path..."
      read -e -rp "> " nginxpath </dev/tty
      NGINX_PATH="${nginxpath}"
      test_docker_compose
    done
  else
    echo "Please run this script from the Fab-manager's installation folder"
    exit 1
  fi
  SERVICE="$(yq eval '.services.*.image | select(. == "nginx*") | path | .[-2]' docker-compose.yml)"
}

test_docker_compose()
{
  if [[ -f "$NGINX_PATH/docker-compose.yml" ]]
  then
    docker-compose -f "$NGINX_PATH/docker-compose.yml" ps | grep nginx
    if [[ $? = 0 ]]
    then
      printf "nginx found at %s\n" "$NGINX_PATH"
      TYPE="DOCKER-COMPOSE"
    fi
  fi
}

proceed_upgrade()
{
  files=()
  while IFS=  read -r -d $'\0'; do
      files+=("$REPLY")
  done < <(find "$NGINX_PATH" -name "*.conf" -print0 2>/dev/null)
  for file in "${files[@]}"; do
    read -rp "Process \"$file\" (y/N)? " confirm </dev/tty
    if [[ "$confirm" = "y" ]]; then
      sed -i.bak -e 's:location ^~ /assets/ {:location ^~ /packs/ {:g' "$file"
      echo "$file was successfully upgraded"
    fi
  done
}


docker_restart()
{
  docker-compose -f "$NGINX_PATH/docker-compose.yml" restart "$SERVICE"
}

function trap_ctrlc()
{
  echo "Ctrl^C, exiting..."
  exit 2
}

upgrade_directive()
{
  trap "trap_ctrlc" 2 # SIGINT
  config
  proceed_upgrade
  docker_restart
  printf "upgrade complete\n"
}

upgrade_directive "$@"
