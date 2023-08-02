FROM golang:1.20 as base
WORKDIR /usr/src/app

FROM base AS package
RUN set -eux; \
        apt-get update; \
        apt-get install -y --no-install-recommends \
            wkhtmltopdf \
            libwebp-dev \
            libvips-dev \
            libheif-examples\
        ; \
        rm -rf /var/lib/apt/lists/*

FROM base AS modules
COPY go.* .
RUN go mod tidy

COPY . .
RUN cd ./scripts && go build main.go

FROM package AS app
COPY --from=modules /usr/src/app/scripts/main .
COPY --from=modules /usr/src/app/scripts/assets ./assets

CMD ["./main"]
