#!/bin/bash

MAIN_CLASS=$1

if [ "$MAIN_CLASS" == '' ]
then
  echo "Usage: $0 <main class>"
  exit 1
fi

# Note: aspectjrt needed for boot vm
java -Djava.security.manager -Djava.security.policy=sandboxpolicy \
     -Dproject.path=$2 \
     -Xbootclasspath/p:./resources/aspectjrt-1.8.9.jar:./newrt.jar \
     -cp ./out/production/cs5231-project/ $MAIN_CLASS & echo $!

