#!/bin/sh

cpp -P "BadMutexC.h" | perl -pe "s/^\n$//g" > BadMutexC.processed.h
cat "BadMutex.moon" | perl -pe "s/___INCLUDE___/`cat BadMutexC.processed.h`/" > "BadMutex.processed.moon"
rm "BadMutexC.processed.h"
moonc "BadMutex.processed.moon"
