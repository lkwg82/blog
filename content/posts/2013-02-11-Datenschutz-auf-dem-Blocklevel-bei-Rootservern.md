---
title: "Datenschutz auf dem Blocklevel bei Rootservern"
date: 2013-02-11T15:38:00Z
lastmod: 2013-02-11T15:38:00Z
draft: false
tags: ["linux", "server", "encryption", "cryptsetup"]
---

Ich habe vor kurzem meinen Server umgezogen. Dabei ging es mir vorallem um mehr Speicherplatz. Die Kapazität ohne monatliche Mehrkosten konnte ich von 750GB auf 3TB erhöhen.

So ein Umzug ist auch immer ein Neuanfang. Ja, so pathetisch wie es klingt, so denkt man auch ... ganz kurz. Ich habe mir vorgenommen einige Sachen besser zu machen.

Bei meinem letzten Umzug waren die großen Veränderungen, dass ich die einzelnen Dienste in autonome virtuelle Maschine portiert. Diese VMs laufen nun in einem virtuellen Netz auf dem Server, mittels Virtualbox. Läuft alles wunderbar und man kann schnell mal experimentieren und neue VMs dazupacken.

Bei *diesem* Umzug war mir Datensicherheit sehr wichtig. Zeitgleich ist mir zuhause eine 2TB Platte peu-à-peu kaputt gegangen. Beim Dumpen der Daten ist mir dann wieder bewußt geworden, dass auch lokal bei 100MB/s immer noch knappe 6h zum Kopieren notwendig sind. Ich versuche meine kaputten Platten vor dem Verschrotten meistens noch einige Runden zu shreddern.

Bei meinem neuen Rootserver habe ich mir überlegt mit einer Basisverschlüsselung, kann ich mir das Shreddern sparen. Dank AES und schnellen Prozessoren ist der Leistungsabfall recht gering und verschmerzbar.

**Ziel: Absicherung bei Server-/Festplattentausch**

### Vorgehensweise:

Aufbauend auf diesen Anleitungen [Festplattenverschlüsselung mit Debian GNU/Linux](http://www.andreas-janssen.de/cryptodisk.html) und [CryptoPartitionHowTo](https://web.archive.org/web/20131205032212/https://systemausfall.org/wikis/howto/CryptoPartitionHowTo) habe ich `cryptsetup` eingesetzt.

Die Formatierung, wie in den Anleitungen angegeben (mit luks) und dann ...

`/etc/crypttab`

```bash
...
crypted-md2     /dev/md2        /etc/disk.key   luks
...
```

`lvm config`

```bash
# lvs
  LV         VG          Attr     LSize   Pool Origin Data%  Move Log Copy%  Convert
  vm         raid1       -wi-ao-- 400.00g
...
```

`/etc/fstab`

```bash
...
/dev/raid1/vm                   /vm             ext4 defaults 0 0
...
```

### kleines Benchmark

Zuerst von der "rohen" Festplatte, dann vom verschlüsselten Gerät. Der Arbeitspeicher hat die Größe von 12GB, daher nehme ich zum Test mehr, dass mir kein Caching dazwischen kommt.

```bash
root@wirt2:~# hdparm -t /dev/sda

/dev/sda:
 Timing buffered disk reads: 356 MB in  3.00 seconds = 118.53 MB/sec
```

von der Festplatte `/dev/sda`

```bash
root@wirt2:/vm# time dd if=/dev/sda bs=1M count=10k  > /dev/null
10240+0 records in
10240+0 records out
10737418240 bytes (11 GB) copied, 82.7227 s, 130 MB/s

real 1m22.725s
user 0m0.404s
sys 0m22.109s
```

aus der Datei `/vm/x`

```bash
root@wirt2:/vm# time dd if=x bs=1M count=10k > /dev/null
10240+0 records in
10240+0 records out
10737418240 bytes (11 GB) copied, 80.9839 s, 133 MB/s

real 1m20.986s
user 0m0.248s
sys 0m16.261s
```

Aufgrund der Zahlen läßt sich abschätzen, dass die Grundverschlüsselung bei heutigen Prozessoren durchaus tragbar ist, sofern die Last niedrig bis mittel ist. Mit [AES-NI](http://datacenteroverlords.com/2011/09/07/aes-ni-pimp-your-aes/) sollte es dann weiter im Grundrauschen versinken. (Auf diesem Server ist ein i7 CPU 975 @ 3.33GHz.)

