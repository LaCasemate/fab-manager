#!/usr/bin/env bash

yq() {
  docker run --rm -i -v "${PWD}:/workdir" mikefarah/yq:4 "$@"
}

config() {
  SERVICE="$(yq eval '.services.*.image | select(. == "sleede/fab-manager*") | path | .[-2]' docker-compose.yml)"
}

run()
{
  config
  docker-compose exec "$SERVICE" bundle exec rails "${@:-c}" </dev/tty
}

run "$@"
