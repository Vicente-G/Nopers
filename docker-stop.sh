#!/bin/bash

stop_container() {
    container_name=$1
    docker stop ${container_name} > /dev/null
    docker rm ${container_name} > /dev/null
}

opt_stop_containers() {
    container_name=$1
    if [ "$(docker ps -q -f name=${container_name})" ]; then
        echo "Container ${container_name} is running. Stopping it..."
        stop_container $container_name
    else
        echo "Container ${container_name} is not running. Skipped."
    fi
}

switch=true

for hash in "$@"; do
    if [ "$switch" = false ]; then break; fi
    case $hash in
        --help)
            echo "Usage: ./docker-stop.sh [HASH(ES)]"
            echo "  Stop running containers of Geocitizen."
            echo "  And optionally, stop other containers by its hash."
            echo -e "\nOptions:"
            echo -e "  --all     Stop and remove all containers."
            echo -e "  --help    Show this help message and exit.\n"
            exit 0
            ;;
        --all)
            echo "Stopping all running containers..."
            if [ "$(docker ps -a -q)" ]; then
                if [ "$(docker ps -q)" ]; then
                    docker stop $(docker ps -q) > /dev/null
                fi
                docker rm $(docker ps -a -q) > /dev/null
            else
                echo "No containers running. Skipped."
            fi 
            switch=false
            ;;
        *)
            echo "Stopping container of hash ${hash:0:12}..."
            stop_container $hash
            ;;
    esac
done

if [ "$switch" = true ]; then
    opt_stop_containers "postgres10v1"
    opt_stop_containers "geocitizenv1"
    opt_stop_containers "geocitizen-frontv1"
fi

echo -e "\nAll clean! 🚀\n"
