---
title: "Aufnahme von Ton mit pulseaudio"
subtitle: "Streaming Spotify"
date: 2015-04-29T21:23:07Z
lastmod: 2015-04-29T13:36:07Z
draft: false
tags: ["pulseaudio", "ubuntu"]
---

Ich habe heute vergeblich versucht meinen Spotify Sound per Streaming auf meinen Raspberry PI zu streamen. Ich hatte leider regelmäßig immer wieder Aussetzer.  
Trotzdem schildere ich hier mal für andere. Vielleicht bekommt das jemand hin und schreibt mir das.

## Anwendung finden

```bash
$ pacmd list-sink-inputs
1 sink input(s) available.
    index: 16
	driver: <protocol-native.c>
	flags: START_CORKED
	state: RUNNING
	sink: 1 <alsa_output.pci-0000_00_1b.0.analog-surround-41>
	volume: front-left: 30309 /  46% / -20,09 dB,   front-right: 30309 /  46% / -20,09 dB
	        balance 0,00
	muted: no
	current latency: 1887,44 ms
	requested latency: 123,81 ms
	sample spec: s16le 2ch 44100Hz
	channel map: front-left,front-right
	             Stereo
	resample method: copy
	module: 10
	client: 136 <spotify>
	properties:
		media.role = "music"
		media.name = "Spotify"
		application.name = "spotify"
		native-protocol.peer = "UNIX socket client"
		native-protocol.version = "30"
		application.process.id = "7869"
		application.process.user = "lars"
		...
		module-stream-restore.id = "sink-input-by-media-role:music"
```

Aufnehmen, als Opus Audio-Codec transkodieren und im VLC abspielen. (Der Enkoder erkennt das RAW-Format korrekt.)

```bash
$ pamon --monitor-stream=16 -r | opusenc --max-delay 100 --framesize 20 --raw - - | vlc -
```

Eigentlich müsste nun nur noch folgendes fehlen (mp3 weil vlc es dann direkt erkennt, ja ich weiß eine Krücke.):

```bash
$ pamon --monitor-stream=16 -r | opusenc --max-delay 100 --framesize 20 --raw - - | avconv -f ogg -i - -acodec mp3 -f rtp rtp://226.0.0.1:1025
```

Anhören und Aussetzer genießen.

```bash
$ vlc rtp://226.0.0.1:1025
```

Weiter komme ich leider nicht.

