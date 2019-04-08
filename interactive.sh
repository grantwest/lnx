#!/bin/bash

docker build -t volta-dev -f Dockerfile.dev .

docker run -it --rm \
-u $(id -u):$(id -g) \
-v $(pwd):/src \
-w /src \
--name volta_dev \
volta-dev /bin/bash
