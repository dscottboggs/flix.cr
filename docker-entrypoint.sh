#!/bin/sh

set -eux

export flix_config="${flix_config:-/config}"

flix \
  --dir "${flix_media_dir:-/media}" \
  --config "${flix_config}" \
  --port "${flix_port:-80}" \
  --webroot "${flix_webroot:-/webui}"
