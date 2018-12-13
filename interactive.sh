#!/bin/bash

docker build --pull -t volta-dev -f Dockerfile.dev .

docker run -it --rm \
-u $(id -u):$(id -g) \
-v $(pwd):/src \
-w /src \
volta-dev /bin/bash
