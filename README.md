# flix

WIP Media server in crystal/kemal.
Serves videos from one or more directories with a ReactJS web app or over a simple API.

## Installation

Crystal allows compiling to a single self-contained executable. I'll drop one of
those in the "releases" section of the repo.

Please note that statically-linked crystal binaries still require the presence
of glibc.

### From source
When installing from source, you must have the development libraries for libmagic. On Ubuntu, it's available as the `libmagic-dev` package.

Run the following commands in the directory you wish to download the source to.
```sh
git clone https://github.com/dscottboggs/flix.cr.git # clone this repository
cd flix.cr      # change working directory to the repository
shards install  # install dependencies
crystal build --release --static -o /usr/local/bin/flix.cr src/flix.cr # build and install
flix.cr --port 8080 # run the server, exposing it on port 8080
```

### Deployment with the frontend
There is a frontend being developed in parallel to this server in React.JS. It can be found at https://github.com/dscottboggs/flix-webui. If you want to deploy with the frontend available, follow these instructions *instead* of those above.
```sh
git clone https://github.com/dscottboggs/flix-webui.git # clone the webui
git clone https://github.com/dscottboggs/flix.cr.git # clone this repository
cd flix.cr      # change working directory to the repository
shards install  # install dependencies
sudo crystal build --release --static -o /usr/local/bin/flix src/flix.cr # build and install
cd ../flix-webui
npm install # install frontend dependencies
npm run build # compile JS (for compatibility and size)
flix_webroot=$PWD/build flix --port=8080 # starts serving.
```

## Usage

See the output of `--help` for command line usage.

### API endpoints
This can be used without a frontend using `curl` and `mpv` or other similar software. For example:

```sh
media_server --port 8888 &
curl localhost:8888/dmp
curl localhost:8888/vid/received_vid_hash | mpv -
```

| endpoint | action       |
|--------|---------------------------------------------------------------------|
| `/dmp` | Returns a json-encoded object, in which each key is a unique identifier, and each value is a human-readable title, or another similarly structured object, representing a child directory. Each object also contains up to two special keys, "title", which is the title of the folder; and "thumbnail", which is the identifier for requesting the thumbnail for that directory. |

This object representation is all you need to access all the data on each
item. Thumbnail images can be retrieved with this endpoint:

| endpoint | action       |
|--------|---------------------------------------------------------------------|
| `/img` | Requires a "id" URL parameter, like `/img?id={value}`, where id is the unique identifier returned by the /titles endpoint. Returns the image as a blob. |
| `/img/{id value}` | The id can be placed directly in the URL path, like so.|

And it's the same with the videos:

| endpoint | action       |
|--------|---------------------------------------------------------------------|
| `/vid` | Requires a "id" URL parameter, like `/vid?id={value}`, where "id" is the unique identifier specified in the /titles endpoint. Returns the raw mp4 video stream. |
| `/vid/{id value}` | The id can be placed directly in the URL path, like so.|

So just by knowing that unique ID, you can access all the public-facing
attributes for that video. When I add subtitles, there will be this endpoint
in the spirit of the first two:

| endpoint | action       |
|--------|---------------------------------------------------------------------|
| `/srt` | Requires a "id" URL parameter, like `/srt?id={value}`, where "id" is the unique identifier specified in the /titles endpoint. Returns a subtitle file (.srt) |

## Contributing

1. Fork it (https://github.com/dscottboggs/flix.cr.git)
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request

Please include an appropriate `spec` file and ensure that `crystal spec` passes.

## Contributors

- [dscottboggs](https://github.com/dscottboggs) D. Scott Boggs - creator, maintainer
