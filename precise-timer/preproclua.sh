#!/bin/sh

cpp -P "PreciseTimerC.h" | perl -pe "s/^\n$//g" > PreciseTimerC.processed.h
cat "PreciseTimer.moon" | perl -pe "s/___INCLUDE___/`cat PreciseTimerC.processed.h`/" > "PreciseTimer.processed.moon"
rm "PreciseTimerC.processed.h"
moonc "PreciseTimer.processed.moon"
