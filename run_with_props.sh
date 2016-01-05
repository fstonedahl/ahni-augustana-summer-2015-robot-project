#!/bin/bash


if [[ $# -lt 1 ]]; then
  echo "Basic usage: $0 path/to/file.properties [-numthreads XX] [other options]" 
  echo 
  echo "More detailed usage info for underlying Java program: "
  java -cp "$NETLOGO/NetLogo.jar:./ahni.jar" com.ojcoleman.ahni.hyperneat.Run
  exit 1
fi

java -cp "$NETLOGO/NetLogo.jar:./ahni.jar" com.ojcoleman.ahni.hyperneat.Run $@

