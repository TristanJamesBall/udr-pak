#!/bin/bash

onstat -g glo |awk '$3 == "cpu" { printf("%s%s",sep,$2); sep="," } END {printf "\n"} '
