# flix

WIP Media server in crystal/kemal.
Serves videos from one or more directories with a ReactJS web app or over a simple API.

## Installation

Crystal allows compiling to a single self-contained executable. I'll drop one of
those in the "releases" section of the repo.

Please note that statically-linked crystal binaries still require the presence
of glibc.

#### From source
Run the following commands in the directory you wish to download the source to.
```sh
git clone https://github.com/dscottboggs/flix.cr.git # clone this repository
cd flix.cr      # change working directory to the repository
shards install  # install dependencies
crystal build --release --static -o /usr/local/bin/flix.cr src/flix.cr # build and install
flix.cr --port 8080 # run the server, exposing it on port 8080
```

## Usage

TODO: Write usage instructions here

## Development

TODO: Write development instructions here

## Contributing

1. Fork it (https://github.com/dscottboggs/flix.cr.git)
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request

## Contributors

- [dscottboggs](https://github.com/dscottboggs) D. Scott Boggs - creator, maintainer
