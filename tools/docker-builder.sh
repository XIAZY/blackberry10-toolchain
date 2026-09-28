#!/bin/sh
set -eu

image=${BB10_BUILDER_IMAGE:-bb10-builder:latest}
action=${1:-build}
repo=$(cd "$(dirname "$0")/.." && pwd)
if [ "$#" -gt 0 ]; then
    shift
fi

case "$action" in
    image)
        cd "$repo"
        exec docker buildx bake bb10-builder
        ;;
    doctor)
        exec docker run --rm "$image" bb10-toolchain-doctor
        ;;
    build|compile|check|shell)
        project_arg=${1:-"$repo/examples/calculator"}
        if [ ! -d "$project_arg" ]; then
            echo "error: project directory not found: $project_arg" >&2
            exit 2
        fi
        project=$(cd "$project_arg" && pwd)

        if [ "$action" = check ]; then
            exec docker run --rm \
                -v "$project:/src:ro" \
                "$image" \
                bb10-check-project /src
        fi

        if [ "$action" = shell ]; then
            exec docker run --rm -it \
                --user "$(id -u):$(id -g)" \
                -e HOME=/tmp/bb10-home \
                -v "$project:/src" \
                "$image" \
                bash
        fi

        if [ "$action" = compile ]; then
            set -- --compile-only
        else
            set --
        fi

        exec docker run --rm \
            --user "$(id -u):$(id -g)" \
            -e HOME=/tmp/bb10-home \
            -v "$project:/src" \
            "$image" \
            bb10-build "$@" /src
        ;;
    *)
        echo "usage: $0 [image|doctor|check|build|compile|shell] [project-directory]" >&2
        exit 2
        ;;
esac
