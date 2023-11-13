#!/bin/bash

find . -maxdepth 1 -type f -name "*.ent" -exec basename {} \; > "config.txt"