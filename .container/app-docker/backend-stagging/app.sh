#!/usr/bin/env docker.sh

# make sure we are using bash
[ -n "${BASH_VERSION:-}" ] || exec bash "$0" "$file" "$@"

# Search port from .env
PWD="$(pwd)"
ENV="$PWD/.env"
PORT=$(grep -oP '(?<=PORT=)\d+' $ENV)

# rollback: change this to spesific version if something goes wrong
image=localhost:5000/backend-setoko-stagging:latest
opts="
    --restart=always
    --net=host
    --env-file=$ENV
    -e PORT=$PORT
    -e LOG_PATH=/var/log/setoko/today.log
    -v "$PWD/log":/var/log/setoko
    -v /var/www/html:/var/www/html
    -p $PORT:$PORT
"

do_cmd_silent() {
    echo "+ $@"
    "$@" >/dev/null
}

command_rotate_and_update() {
    # define tag array
    tag_arr=(
        localhost:5000/backend-setoko-stagging:latest-known-working-{3,2,2,1,1}
        localhost:5000/backend-setoko-stagging:latest
    )

    # check if eligible
    if [[ $image != ${tag_arr[-1]} ]]; then
        echo "not doing it, because of image pointing to specific rollback version"
        exit 0
    fi

    # rotate tag
    for ((i = 0; i < ${#tag_arr[@]}; i += 2)); do
        do_cmd_silent docker tag "${tag_arr[$((i + 1))]}" "${tag_arr[$i]}"
        do_cmd_silent docker push "${tag_arr[$i]}"
    done
    do_cmd_silent docker pull "${tag_arr[-1]}"

    # update running app
    echo "+ update"
    main update -n
}

command_start() {
    main start -n
}
