#!/bin/sh
set -eux
cd /tmp
rm -rf borken
crystal init app borken
cd borken
cat << EOF > shard.yml
name: borken
version: 1.0.0

targets:
  borken:
    main: src/borken.cr

dependencies:
  kemal-auth-token:
    github: dscottboggs/kemal-auth-token

EOF

printf 'require "kemal-auth-token"\n' > src/borken.cr

shards install
crystal spec

