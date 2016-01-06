#!/bin/bash

rsync -au ahni.jar "$LOVELACE:~/robotbrains/"
rsync -au models/ "$LOVELACE:~/robotbrains/models/"
rsync -au properties_robotbrain/ "$LOVELACE:~/robotbrains/properties_robotbrain/"
rsync -au run_with_props.sh "$LOVELACE:~/robotbrains/"
