#!/bin/bash

# When you run "./manage.sh start"
if [ "$1" = "start" ]; then
    # Just start the container and give you a shell
    docker-compose up -d
    docker-compose exec -u flintx bolt bash

# When you run "./manage.sh stop"
elif [ "$1" = "stop" ]; then
    # Stop the container
    docker-compose down

# When you run "./manage.sh rebuild"
elif [ "$1" = "rebuild" ]; then
    # Rebuild and start the container
    docker-compose build
    docker-compose up -d
    docker-compose exec -u flintx bolt bash

# When you run "./manage.sh clean"
elif [ "$1" = "clean" ]; then
    # Full cleanup and rebuild
    docker-compose down --rmi all
    docker-compose build
    docker-compose up -d
    docker-compose exec -u flintx bolt bash

# If you run it wrong
else
    echo "Usage: ./manage.sh start|stop|rebuild|clean"
fi
