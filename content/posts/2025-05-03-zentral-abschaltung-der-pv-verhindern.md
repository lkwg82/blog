---
layout: post
title: Zentrale Abschaltung der PV Anlage verhindern 
date: 2026-05-03T08:27:34+01:00 
---

# Abschaltung des Wechselrichters verhindern


Wir haben eine Photovoltaikanlange mit Wechselrichter von SolarEdge und Batterie. Seit Ostersontag 2026 habe 
ich zu Zeiten, zu denen die Strompreise negativ sind, beobachtet, dass der Wechselrichter in einen 'Pause'-Modus versetzt wird. 
Dadurch wird weder die Batterie noch der aktuell produzierte Strom für den Eigenverbrauch herangezogen.

Ich bin damit einverstanden, dass die Einspeisung ausgesetzt wird, aber nicht, dass ich zu dieser Zeit aktiv aus dem Netz
Strom beziehe.

## Problem

Netzbezug, trotz vorhandener Ladung in Batterie und Leistung der PV Anlage

## Lösung

Wechselrichter zu den Zeiten negativer Börsenstrompreise vom Internet trennen.

## Umsetzung

1. Per cronjob wird ein Skript ausgeführt, welches per API auf dem unifi Gerät den Wechselrichter passend trennt/verbindet.
2. Preise kommen von der Awattar API (kein Authentifizierungstoken notwendig).
3. Benachrichtigung über https://ntfy.sh, dass ein Wechsel stattgefunden hat.

### Details

Das Skript wird stündlich ausgeführt. 


![Übersicht](/img/20260503_091912_block_inet.png)

Einmal am Tag werden die Preise von der Awattar-API geholt und zwischengespeichert. (nach 15 Uhr)

![/img/20260503_093309_block_inet2.png](/img/20260503_093309_block_inet2.png)

Beim Blockieren wird eine Benachrichtigung versendet (und bei der Freischaltung).

---
Vollständiges Script:
https://gist.github.com/lkwg82/aa4758d70171458caec7365deec934af