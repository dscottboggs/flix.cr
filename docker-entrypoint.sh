#!/bin/sh

set -eux

create_first_user() {
  user="${flix_first_user:-admin}"
  password="${flix_first_user_password:-`crystal eval 'puts Random::Secure.base64.strip "="'`}"
  echo "no users found, creating first user '$user' with password '$password'."
  echo "this password isn't saved anywhere else, make sure you save it."
  ./scripts/user_modifications add --file $1 --user $user --password $password
}

flix_dir=$(dirname $(realpath $0))
export flix_config="${flix_config:-/config}"
auth_file="$flix_config/users.auth"

cd $flix_dir
[ -f $auth_file ] || create_first_user $auth_file
# run the tests if the $run_specs environment variable is set
[ -z ${run_specs+is_set} ] || crystal spec

flix \
  --dir "${flix_media_dir:-/media}" \
  --config "${flix_config}" \
  --port "${flix_port:-80}" \
  --webroot "${flix_webroot:-/webui}"
