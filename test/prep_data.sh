#!/bin/bash

# bring containers down
docker-compose down || true;

# pull the images
docker-compose pull;

# start elasticsearch if it's not already running
if ! [ $(curl --output /dev/null --silent --head --fail http://localhost:9200) ]; then
    docker-compose up -d elasticsearch;

    # wait for elasticsearch to start up
    echo 'waiting for elasticsearch service to come up';
    until $(curl --output /dev/null --silent --head --fail http://localhost:9200); do
      printf '.'
      sleep 2
    done
fi

# create the index in elasticsearch before importing data
curl -XDELETE 'localhost:9200/pelias?pretty'
docker-compose run --rm schema npm run create_index;

# download all the data to be used by imports
. ../who_date.sh
if $UPDATE_WHO ; then
  docker-compose run --rm whosonfirst npm run download;
fi

docker-compose run --rm transit npm run download;
docker-compose run --rm transit npm start;
