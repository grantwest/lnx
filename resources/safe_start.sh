#!/bin/bash
"$@" &
pid=$!
while read line ; do
  :
done
kill $pid
