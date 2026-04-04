---
title: "Automatischer Bilderimport beim Anschluss der Kamera"
subtitle: "mit Thunar unter Xfce"
date: 2015-05-20T21:23:07Z
lastmod: 2015-05-20T13:36:07Z
draft: false
tags: ["thunar", "gphoto2", "renrot", "ubuntu"]
---

Da ich unter Ubuntu nichts adäquates finde, um automatisch meine Bilder zu importieren. Habe ich das Ganze mit einem Shellskript und [Thunar](http://de.wikipedia.org/wiki/Thunar) (ist der Dateimanager von [Xfce](http://xfce.org/)) gelöst. Der Import startet sobald die Kamera erkannt wird.

Folgende Anwendungen bitte installieren:

```bash
sudo apt-get install gphoto2 renrot
```

Dieses Skipt unter `~/bin/importBilder.sh` ablegen.

```bash
#!/bin/bash

set -e

exitEnter()     { echo $1; echo "press ENTER to exit"; read; exit 1; }
checkInstalled(){
    printf "checking %-30s installed : "  $1;
    type $1 >/dev/null 2>&1 && echo "ok" || { echo "fail"; exitEnter; }
}

checkInstalled gphoto2
checkInstalled renrot
checkInstalled thunar
# optional
# checkInstalled convertCamVideo2ArchivVideo.sh

imageFolder=$(echo ~/Bilder)

serialNumber=$( gphoto2 --get-config /main/status/eosserialnumber | grep ^Current | cut -d\  -f2)  || { exitEnter; }

doImport(){
    timestamp=$(printf %s $(date +"%Y%m%d_%H%M"))
    local folder="$imageFolder/autoimport_$timestamp"
    mkdir -p $folder
    cd $folder && gphoto2 -P

    # use exif to rename the file
    renrot --mtime --name-template "%Y%m%d_%H%M_%n" *.JPG

    mkdir _jpeg_original
    mv *JPG_orig _jpeg_original/

    mkdir raw
    mv *CR2 raw/

    # transcoding video to lower file size
    # convertCamVideo2ArchivVideo.sh

    echo
    echo "finished import into '$folder'"
    echo
    echo "press Enter to exit"
    read

    thunar $folder
}

# only import from a specific camera, not any other
if [ $serialNumber -eq 2131234489 ]; then
    doImport
fi
```

## Screenshots

[![Version von Thunar](/img/2015-05-20-version-thunrar-small.jpg)](/img/2015-05-20-version-thunrar.jpg)
[![Erweiterte Eigenschaften](/img/2015-05-20-advanced-settings-thunrar-small.jpg)](/img/2015-05-20-advanced-settings-thunrar.jpg)
[![Volumed Eigenschaften](/img/2015-05-20-camera-volumd-small.jpg)](/img/2015-05-20-camera-volumd.jpg)
[![Terminalausgabe wenn die Kamera angeschlossen wird](/img/2015-05-20-terminal-small.jpg)](/img/2015-05-20-terminal.jpg)
[![So sieht es dann im Browser aus](/img/2015-05-20-thunar-small.jpg)](/img/2015-05-20-thunar.jpg)

So sieht dann die Ausgabe aus:

```bash
checking gphoto2                        installed : ok
checking renrot                         installed : ok
checking thunar                         installed : ok

Downloading 'IMG_0210.CR2' from folder '/store_00020001/DCIM/101CANON'...
Speichere Datei als IMG_0210.CR2
Downloading 'IMG_0210.JPG' from folder '/store_00020001/DCIM/101CANON'...
Speichere Datei als IMG_0210.JPG

...

Downloading 'IMG_0220.CR2' from folder '/store_00020001/DCIM/101CANON'...
Speichere Datei als IMG_0220.CR2
Downloading 'IMG_0220.JPG' from folder '/store_00020001/DCIM/101CANON'...
Speichere Datei als IMG_0220.JPG

RENAMING / ROTATING
===================
Processing file: (1 of 11) IMG_0210.JPG...
Renamed: IMG_0210.JPG -> 20150515_1406_IMG_0210.JPG

...

Processing file: (11 of 11) IMG_0220.JPG...
Renamed: IMG_0220.JPG -> 20150515_1416_IMG_0220.JPG


finished import into '/home/lars/Bilder/autoimport_20150520_1027'

press Enter to exit
```

Viel Spaß damit!

