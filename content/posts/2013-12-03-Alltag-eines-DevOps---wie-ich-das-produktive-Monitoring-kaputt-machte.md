---
title: "Alltag eines DevOps - wie ich das produktive Monitoring kaputt machte"
date: 2013-12-03T22:14:08Z
lastmod: 2013-12-03T22:14:08Z
draft: false
tags: ["devops", "monitoring", "cld"]
categories: ["devops", "monitoring", "cld"]
---
 
Ich arbeite in einer (wirklich tollen) Firma, die sich vielen modernen Themen annimmt und diese versucht *zu leben*.

*zu leben*

> Das bedeutet, dass wir einem aufgeplusterten Buzzword versuchen Leben einzuhauchen. So z.B. achten wir nicht auf Qualität ... wir *leben* Qualität. Wir schämen uns für Fehler. Wir lernen aktiv aus Fehlern. Wir analysieren grobe Fehler und leiten Strategien ab, die proaktiv in Verhaltensänderungen überführt werden (sollen). Wir laden es (das Buzzword) so mit Emotionen aus, dass es kaum noch infrage gestellt wird. Dann *leben* wir es so intensiv, dass wir alle Übertreibungen einmal erfahren haben und uns bildlich gesprochen mindestens einmal die Augen ausgeheult haben. Danach finden wir meist ein ganz gesundes Mittelmaß und begegnen neue Hypes, die wir durchleben.

So ist das auch bei Continuous Live Deployment (kurz CLD). Kurz beschrieben ist CLD die Weiterentwicklung von Continuous Integration zu kleinen kurzen Releasezyklen. Bei [Martin Fowler](http://martinfowler.com/delivery.html) sind dazu verschiedene verwandte Themen beschrieben.

Nun das klingt sehr interessant. Schnell und oft neue Versionen dem Nutzer bereitstellen. Allerdings wird vergessen, dass einige [Vorraussetzungen](http://www.pingworks.de/continuous-delivery-umsetzung/) erfüllt werden müssen (Automatisierte Tests, CI, CM, DevOps).

Wir sind mittlerweile so doll CLDisiert, dass wir einige Vorbedingungen vergessen. Das ist der Moment des *intensiven Durchlebens*. Ich glaube wir haben Phasen jugendlicher Leichtigkeit bei der Umsetzung neuer Trends.

Bei uns ist CLD mittlerweile in der Administration unserer produktiven System angekommen. Wir sind soweit, dass wir nicht nur Software, die unsere Geschäftslogik enthält, à la CLD herausgeben, sondern auch Software die für den Betrieb eben dieser erforderlich ist, so handhaben. So auch das Monitoring.

So kam es nun, dass ein Entwickler (ich) gegen 19 Uhr nach langem Kampf als DevOps mit [Icinga](https://www.icinga.org/) Änderungen in der Konfiguration committed hat. Mit CLD vergeht ein Fingerschnippen und alle Tests sind durchlaufen, es wird gestaged und wieder laufen alle Tests und im Nu ist es live.

Oder auch nicht - weil .... wir leider kontinuierlichen stagen und sofort live schieben, aber an eben dieser kleinen spröden Monitoringkonfiguration das Testen vergessen haben.

Ich habe dann committed und ... hier ist Fehler 1 ... mich darauf verlassen, dass Fehler durch Tests bemerkt werden und nicht zu Beeinträchtigungen führen. Leider ist durch ... Fehler 2 ... fehlenden Tests keine Fehler aufgefallen und direkt bis in die produktiven Systeme propagiert worden ... mit allen Konsequenzen.

Der Fehler wurde von der Rufbereitschaft dann jedoch wieder in 5 Minuten gefixt.

Da wir allerdings Qualität *leben*, haben wir am nächsten Tag gemeinsam das Problem analysiert und einige Tests aka [Quality Gate](http://de.wikipedia.org/wiki/Quality_Gate) eingearbeitet.

**Fazit:**

CLD ist beeindruckend, allerdings ohne eine gute Qualitätsinfrastruktur auch zerstörerisch.

