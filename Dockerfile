FROM golang:1.20 as base
WORKDIR /usr/src/app

# FROM base AS package
# RUN apt-get update && apt-get install -y --no-install-recommends \
#         libwebp-dev \
#         xvfb \
#         libfontconfig \
#         wkhtmltopdf \
#         libheif-dev \
#         libvips \
#         libvips-dev \
#         libvips-tools \
#         libheif-examples

FROM base AS modules
COPY go.* .
RUN go mod download

FROM base AS app
COPY . .
RUN cd ./scripts && go build main.go

CMD ["./scripts/main"]
