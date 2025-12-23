---
title: "Howto Babyphone mit dem Raspberry PI"
date: 2014-02-09T13:08:00Z
draft: false
tags: ["raspberry-pi", "webcam", "streaming"]
---

Bald ist es soweit und das Babyphone muss eingerichtet werden. Dazu habe ich mir die Webcam [Logitech C920](http://www.logitech.com/de-de/product/hd-pro-webcam-c920) und [Raspberry Pi Modell B](http://de.wikipedia.org/wiki/Raspberry_Pi#Spezifikationen) gekauft.

Hier nun meine kleine Anleitung um auf dem Handy Bild und Ton zu haben.

## Vorraussetzungen

Der PI hat Netzzugang und ihr könnt per SSH rauf.

## Schritte zum Erfolg - das Bild {#bild}

Als erstes die Tools installieren:

```bash
$ sudo apt-get update
$ sudo apt-get install build-essential libjpeg-dev imagemagick subversion libv4l-dev
```

Dann [mjpg-streamer](http://sourceforge.net/projects/mjpg-streamer/) installieren (leider gibt es noch kein Binärpaket):

```bash
$ cd /tmp
$ svn co https://svn.code.sf.net/p/mjpg-streamer/code/mjpg-streamer mjpg-streamer
$ cd mjpg-streamer
$ make USE_LIBV4L2=true
$ sudo make install
```

MJPEG-Streamer als Dienst installieren mit diesem Init-skript:

```bash
#!/bin/sh
# /etc/init.d/mjpg_streamer

#
# Creation:    04.02.2013
# Last Update: 04.02.2013
#
# Written by Georg Kainzbauer (http://www.gtkdb.de)
#

### BEGIN INIT INFO
# Provides:          mjpg_streamer
# Required-Start:    $all
# Required-Stop:     $all
# Default-Start:     2 3 4 5
# Default-Stop:      0 1 6
# Short-Description: MJPG-Streamer
# Description:       MJPG-Streamer takes JPGs from Linux-UVC compatible webcams and streams them as M-JPEG via HTTP.
### END INIT INFO

start()
{
  echo "Starting mjpg-streamer..."
  /usr/local/bin/mjpg_streamer -i "/usr/local/lib/input_uvc.so -d /dev/video0 -n" -o "/usr/local/lib/output_http.so -n -w /usr/local/www -p 8080" >/dev/null 2>&1 &
}

stop()
{
  echo "Stopping mjpg-streamer..."
  kill -9 $(pidof mjpg_streamer) >/dev/null 2>&1
}

case "$1" in
  start)
    start
    ;;
  stop)
    stop
    ;;
  restart)
    stop
    start
    ;;
  *)
    echo "Usage: $0 {start|stop|restart}"
    ;;
esac

exit 0
```

und bitte beim nächsten Booten automatisch mitstarten

```bash
$ sudo chmod 0755 /etc/init.d/mjpg_streamer
$ sudo update-rc.d mjpg_streamer defaults
```

Zum Testen einfach den Dienst starten und dann unter `http://<ip>:8080/` anschauen.

```bash
$ sudo service mjpg_streamer start
```

Falls eure Webcam direkt MJPEG unterstützt, gibt es dieses Streaming für unter 5% cpu Last ;).

```bash
sudo v4l2-ctl --list-formats
ioctl: VIDIOC_ENUM_FMT
	Index       : 0
	Type        : Video Capture
	Pixel Format: 'YUYV'
	Name        : YUV 4:2:2 (YUYV)

	Index       : 1
	Type        : Video Capture
	Pixel Format: 'H264' (compressed)
	Name        : H.264

	Index       : 2
	Type        : Video Capture
	Pixel Format: 'MJPG' (compressed)
	Name        : MJPEG
```

Details können unter [[1]](#ubuntuusers) und [[2]](#gtkdb) nachgelesen werden.

## Schritte zum Erfolg - der Ton {#ton}

Ich habe mich dazu entschieden den Ton über http als mp3 anzubieten:

Tools zum Aufnehmen und Konvertieren installieren:

```bash
$ sudo apt-get install libav-tools alsa-utils
```

Mikrophon der Soundkarte herausfinden

```bash
$ sudo arecord -l
**** Liste der Hardware-Geraete (CAPTURE) ****
Karte 1: C920 [HD Pro Webcam C920], Geraet 0: USB Audio [USB Audio]
  Sub-Geraete: 0/1
  Sub-Geraet #0: subdevice #0
```

Daraus ergibt sich die Alsa-Adresse `plughw:1,0`, die wir in den folgenden Init-skript verwenden. Dabei nehmen wir den Ton von der Webcam auf und schicken ihn als mp3 kodiert und als [rtp](https://libav.org/avconv.html#rtp) verpackt an localhost. (Dieser Umweg ist deswegen notwendig, weil vlc in der Version vor 2.1 es nicht hinbekommt den Ton direkt von einem Alsa-Gerät auszulesen.)

`/etc/init.d/audio-record`

```bash
#!/bin/sh
# /etc/init.d/audio-record

### BEGIN INIT INFO
# Provides:          audio-record
# Required-Start:    $all
# Required-Stop:     $all
# Default-Start:     2 3 4 5
# Default-Stop:      0 1 6
# Short-Description: audio-record
# Description:       streams soundcard via rtp over localhost
### END INIT INFO

start()
{
  echo "Starting audiorecord.."
  arecord -f cd -D plughw:1,0 2>/dev/null | avconv -i - -acodec libmp3lame -ac 1 -ab 128k -re -f mp3 -f rtp rtp://127.0.0.1:1234  1>/dev/null 2>&1 &
}

stop()
{
  echo "Stopping audiorecord ..."
  kill -9 $(pidof arecord) >/dev/null 2>&1
  kill -9 $(pidof avconv) >/dev/null 2>&1
}

case "$1" in
  start)
    start
    ;;
  stop)
    stop
    ;;
  restart)
    stop
    start
    ;;
  *)
    echo "Usage: $0 {start|stop|restart}"
    ;;
esac

exit 0
```

Das Ganze greife ich mit vlc ab und biete es als http-stream `/etc/init.d/vlc-http` wieder an:

```bash
#!/bin/sh

### BEGIN INIT INFO
# Provides:          vlc-http
# Required-Start:    $all
# Required-Stop:     $all
# Default-Start:     2 3 4 5
# Default-Stop:      0 1 6
# Short-Description: vlc-http
# Description:       transport rtp from localhost to http
### END INIT INFO

start()
{
  echo "Starting vlc-http .."
  su lars -c "cvlc rtp://127.0.0.1:1234 --sout '#http{dst=:8081/baby.mp3}'" > /dev/null 2>&1  &
}

stop()
{
  echo "Stopping vlc-http ..."
  kill -9 $(pidof vlc) >/dev/null 2>&1
}

case "$1" in
  start)
    start
    ;;
  stop)
    stop
    ;;
  restart)
    stop
    start
    ;;
  *)
    echo "Usage: $0 {start|stop|restart}"
    ;;
esac

exit 0
```

Jetzt wieder beide neuen Init-skripte mit ... aktivieren.

```bash
$ sudo chmod 0755 /etc/init.d/audio-record
$ sudo update-rc.d audio-record defaults
$ sudo chmod 0755 /etc/init.d/vlc-http
$ sudo update-rc.d vlc-http defaults
```

Zum Testen einfach `http://<ip>:8081/baby.mp3` aufrufen und sich nicht über die 2 Sekunden Verzögerung wundern ;).

Alles für nur 50% CPU auf dem PI.

[![Auslastung mittels htop auf dem PI](/img/2014-02-09-htop-pi_small.jpeg)](/img/posts/2014-02-09-htop-pi.jpeg)

## Referenzen

1. <a id="ubuntuusers"></a>[http://wiki.ubuntuusers.de/MJPG-Streamer](http://wiki.ubuntuusers.de/MJPG-Streamer)
2. <a id="gtkdb"></a>[Raspbian: MJPG-Streamer einrichten](http://www.gtkdb.de/index_36_2098.html)

