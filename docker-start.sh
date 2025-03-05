#!/bin/bash

DB_IMAGE="postgres10"
BACKEND_IMAGE="geocitizen"
FRONTEND_IMAGE="geocitizen-front"

CUSTOM_URL=0
FORCE_BUILD=0
CHECK_IF_RUNNING=0
IGNORE_MIGRATION=0

PG_NAME="ss_demo_1"
PG_URL="jdbc:postgresql://localhost:5432/${PG_NAME}"
TC_HOME='/opt/tomcat/apache-tomcat-9.0.100'

for arg in "$@"; do
    if [[ "$arg" = "--help" ]]; then
        echo "Usage: ./docker-start.sh [OPTIONS]"
        echo "  Start the Geocitizen project with Docker."
        echo -e "\nOptions:"
        echo -e "  -R                 Remove all containers before starting."
        echo -e "  -h URL             Use a custom database hosted on URL."
        echo -e "  -n NAME            Use a custom NAME for the database."
        echo -e "  -b                 Force the build of the images before running."
        echo -e "  -s                 Skip the containers already running."
        echo -e "  --help             Show this help message and exit.\n"
        exit 0
    fi
done

while getopts "Rh:n:bsm" opt; do
    case $opt in
        R)  ./docker-stop.sh --all;;
        h)
            CUSTOM_URL=1
            PG_URL=$OPTARG
            ;;
        n)  PG_NAME=$OPTARG;;
        b)  FORCE_BUILD=1;;
        s)  CHECK_IF_RUNNING=1;;
        \?)
            echo -e "Invalid option: -$OPTARG\n"
            exit 1
            ;;
    esac
done

check_success() {
    local status=$1
    local message=$2

    if [[ $status -ne 0 ]]; then
        echo -e "\n[ERROR] $message"
        exit $status
    fi
}

build_image_if_not_exists() {
    local image=$1
    local dockerfile=$2

    if [[ $FORCE_BUILD = 1 || "$(docker images -q $image 2> /dev/null)" = "" ]]; then
        if [[ $FORCE_BUILD = 1 ]]; then
            echo "Forcing the build of image '$image'..."
        else
            echo "Image '$image' not found. Building with Docker..."
        fi
        docker build -t $image -f $dockerfile .
        check_success $? "Error building image '$image'! 💥 Exiting..."
    else
        echo "Image '$image' already exists. Skipping build."
    fi
}

check_db_running() {
    if [[ $CUSTOM_URL = 0 ]]; then
        echo -e "Custom database URL provided. Skipping database check..."
    fi
    if [[ "$(docker ps -q -f name=${DB_IMAGE}v1)" ]]; then
        echo -e "Database container is already running. Skipping..."
    else
        echo -e "Database container not found. Starting..."
        build_image_if_not_exists $DB_IMAGE ./docker/db.Dockerfile
        docker run -d -p 5432:5432 --name ${DB_IMAGE}v1 -e POSTGRES_DB=$PG_NAME $DB_IMAGE
        check_success $? "Error starting Database container! 💥 Exiting..."
        echo -e "Database container started successfully!"
    fi
    return 0
}

echo -e "Starting the Geocitizen project with Docker! 🚀\n"

check_db_running
if [[ $? != 0 && $CHECK_IF_RUNNING = 0 ]] || \
   [[ "$(docker ps -aq -f name=${BACKEND_IMAGE}v1)" && $CHECK_IF_RUNNING = 0 ]] || \
   [[ "$(docker ps -aq -f name=${FRONTEND_IMAGE}v1)" && $CHECK_IF_RUNNING = 0 ]]; then
    echo -e "[WARNING] Mission aborted! 🛑\n"
    echo -e "One or more containers are already running. Check it out with 'docker ps -a'"
    echo -e "Consider stopping them before starting new ones, or skip this with '-s' flag!\n"
    exit 117
fi

build_image_if_not_exists $FRONTEND_IMAGE ./docker/frontend.Dockerfile

if [[ $CHECK_IF_RUNNING = 1 && $(docker ps -q -f name=${BACKEND_IMAGE}v1) ]]; then
    echo -e "\nBackend container already running. Skipping..."
else
    echo -ne "\nStarting Backend container with hash="
    if [[ $CUSTOM_URL = 0 ]]; then
        DOCKER_QUERY='{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}'
        DB_CONTAINER_IP=$(docker inspect --format="$DOCKER_QUERY" ${DB_IMAGE}v1)
        PG_URL="jdbc:postgresql://${DB_CONTAINER_IP}:5432/${PG_NAME}"
    fi
    docker build -t $BACKEND_IMAGE -f ./docker/backend.Dockerfile --build-arg DATABASE_URL=$PG_URL .
    docker run -d -p 8080:8080 --name ${BACKEND_IMAGE}v1 \
        -v ./docker/backend-config/tomcat-users.xml:${TC_HOME}/conf/tomcat-users.xml \
        -v ./docker/backend-config/context.xml:${TC_HOME}/webapps/manager/META-INF/context.xml \
        -e DB_URL=$PG_URL -e REFERENCEURL=$PG_URL -e URL=$PG_URL $BACKEND_IMAGE | head -c 12
    check_success $? "Error starting Backend container! 💥 Exiting..."
fi
echo -e "\nBackend container available. Webapp deployed to [/citizen]"

if [[ $CHECK_IF_RUNNING = 1 && $(docker ps -q -f name=${FRONTEND_IMAGE}v1) ]]; then
    echo -e "\nFrontend container already running. Skipping..."
else
    echo -ne "\nStarting Frontend container with hash="
    docker run -d -p 8081:8081 --name ${FRONTEND_IMAGE}v1 $FRONTEND_IMAGE | head -c 12
    check_success $? "Error starting Frontend container! 💥 Exiting..."
fi
echo -e "\nFrontend container is up. Available on http://localhost:8081/#/"

echo -e "\nAll containers started successfully! 🚀\n"