#!/bin/bash

./ajc -8 -inpath $JAVA_HOME/jre/lib/rt.jar \
        ./src/java/io/SandboxMapping.aj \
        ./src/java/io/FileInputStreamAspect.aj \
        ./src/java/io/FileAspect.aj \
        ./src/java/io/FileOutputStreamAspect.aj \
        -outjar newrt.jar
