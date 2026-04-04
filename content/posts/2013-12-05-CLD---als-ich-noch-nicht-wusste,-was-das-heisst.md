---
title: "CLD - als ich noch nicht wusste, was das heisst"
date: 2013-12-05T22:39:00Z
lastmod: 2013-12-05T22:39:00Z
draft: false
tags: ["devops", "cld", "continuous-delivery"]
---

Im letzten Artikel über meinen Alltag DevOps [Wie ich das Monitoring kaputt machte](/posts/2013-12-03-alltag-eines-devops---wie-ich-das-produktive-monitoring-kaputt-machte/) habe ich CLD angesprochen. Dabei ist mir eine Geschichte aus meiner Anfangszeit bei meinem jetzigen Arbeitgeber eingefallen. Im Nachhinein lustig, damals etwas verunsichernd.

Ich bin also neu in meiner Firma und committe Code. Kurz darauf geht die Live-Plattform aus. Was mir in dem Moment noch nicht bewußt war, dass wir gerade CLD *leben* und ich gerade eine Kehrseite von CLD intensiv erfahre.

Ich habe also committed und dabei einen Teil der Plattform erwischt, die nicht ausreichend abgetestet war. Der noch nicht sichtbare Fehler führte dann mit 10minütiger Zeitverzögerung dazu, dass ich eine unbeabsichtigte Downtime von 20Minuten verursacht habe.

Da ist mir schon kurz etwas heiß geworden ;).

Das war auch, glaube ich der Zeitpunkt, an dem wir von automatischem CLD auf manuelles CLD gewechselt sind.

**Fazit für mich:**

Automatismen der Buildchain sollten den Teilnehmern bewußt sein.

