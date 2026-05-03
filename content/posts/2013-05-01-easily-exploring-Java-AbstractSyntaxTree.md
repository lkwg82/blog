---
title: "easily exploring Java AbstractSyntaxTree"
date: 2013-05-01T13:36:53Z
lastmod: 2013-05-01T13:36:53Z
draft: false
tags: ["java", "ast", "checkstyle"]
---

If you ever need to deal with the AST in java here I'd like to this small tool I've found some time ago.

Start it with:

```bash
java -cp checkstyle-5.6-all.jar com.puppycrawl.tools.checkstyle.gui.Main PomSourceImporter.java
```

It shows this file [de/lgohlke/sonar/PomSourceImporter]`https://github.com/SonarCommunity/sonar-maven-checks/blob/master/src/main/java/de/lgohlke/sonar/PomSourceImporter.java` (💀link)

A nice feature is typing ENTER on an ast node and the corresponding source code will be highlighted as well.

You can get it with checkstyle from [checkstyle.sourceforge.net](http://checkstyle.sourceforge.net), it is also described here [The Checkstyle SDK Gui](http://checkstyle.sourceforge.net/writingchecks.html).

I really appreciated this tool a while ago, when I worked on my [thesis](https://www.lgohlke.de/#arbeiten) and [SelectorMethodArgumentCheck.java] `https://github.com/lkwg82/sonar-java/blob/9dcb5e1864d9deb6ce77c4f5e9c32e856b5a5505/java-checks/src/main/java/org/sonar/java/checks/SelectorMethodArgumentCheck.java` (💀link).

Alternative tools are:

- [AstExplorer](http://web.archive.org/web/20130904230821/http://www.ibm.com:80/developerworks/opensource/library/os-ast/) (tightly coupled with eclipse JDT)
- [eclipse plugin](http://eclipseintrospc.sourceforge.net/reference/views_and_editors/dom_ast_explorer_view.html)

