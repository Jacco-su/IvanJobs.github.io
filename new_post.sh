#!/usr/bin/env bash
# for example: ./new_post.sh hello world
TODAY=`date +%Y-%m-%d`

NAME=_posts/$TODAY
for var in "$@"
do
    NAME=${NAME}-${var}
done

NAME=${NAME}.markdown # name concated with dashes.

touch $NAME

echo "---" >> $NAME
echo "layout: post" >> $NAME
echo "title:" >> $NAME
echo "categories:" >> $NAME
echo "---" >> $NAME

echo 'Done!'

