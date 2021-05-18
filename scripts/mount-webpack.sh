#!/usr/bin/env bash

yq() {
  docker run --rm -i -v "${PWD}:/workdir" mikefarah/yq:4 "$@"
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
  SERVICE="$(yq eval '.services.*.image | select(. == "sleede/fab-manager*") | path | .[-2]' docker-compose.yml)"
  echo -e "\n"
}

change_mount()
{
  if [[ $(yq eval ".services.$SERVICE.volumes.[] | select (. == \"*assets\")" docker-compose.yml) ]]; then
    yq -i eval ".services.$SERVICE.volumes.[] |= select(. == \"*assets\") |= \"\${PWD}/public/packs:/usr/src/app/public/packs\"" docker-compose.yml
    echo "Service volume was replaced for $SERVICE: /assets changed to /packs"
  fi
}

proceed()
{
  config
  change_mount
}

proceed "$@"
