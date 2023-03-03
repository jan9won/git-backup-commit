FROM alpine:latest
RUN apk add bash

COPY ./src ./src

COPY ./test.bash ./test.bash
ENTRYPOINT ./test.bash