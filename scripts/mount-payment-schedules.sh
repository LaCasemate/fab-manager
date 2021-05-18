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

add_mount()
{
  if [[ ! $(yq eval ".services.$SERVICE.volumes.[] | select (. == \"*payment_schedules\")" docker-compose.yml) ]]; then
    # shellcheck disable=SC2016
    # we don't want to expand ${PWD}
    yq -i eval ".services.$SERVICE.volumes += [\"\${PWD}/payment_schedules:/usr/src/app/payment_schedules\"]" docker-compose.yml
  fi
}

proceed()
{
  config
  add_mount
}

proceed "$@"
