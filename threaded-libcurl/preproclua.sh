#!/bin/sh

cpp -P "DownloadManagerC.h" | perl -pe "s/^\n$//g" > DownloadManagerC.processed.h
cat "DownloadManager.moon" | perl -pe "s/___INCLUDE___/`cat DownloadManagerC.processed.h`/" > "DownloadManager.processed.moon"
rm "DownloadManagerC.processed.h"
moonc "DownloadManager.processed.moon"
