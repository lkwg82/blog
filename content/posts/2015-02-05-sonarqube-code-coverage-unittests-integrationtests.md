---
title: "Easy distinct unit and integration test code coverage with sonarqube"
date: 2015-02-05T23:23:07Z
lastmod: 2015-10-25T13:36:07Z
draft: false
tags: ["sonarqube", "coverage", "maven", "java"]
---

Simple compute distinct code coverage for unit tests and integration tests. I used jacoco 0.7.2, sonarqube 5.0 and maven 3.2.5 to cook the numbers ;).

[![screenshot from sonarqube](/img/2015-02-05-combined-code-coverage.jpg)](/img/posts/2015-02-05-combined-code-coverage.jpg)

```xml
<project ...>
    ...
        <profile>
            <id>sonar-coverage</id>
            <build>
                <plugins>
                    <plugin>
                        <groupId>org.jacoco</groupId>
                        <artifactId>jacoco-maven-plugin</artifactId>
                        <version>0.7.2.201409121644</version>
                        <configuration>
                            <append>true</append>
                        </configuration>
                        <executions>
                            <execution>
                                <id>agent-for-ut</id>
                                <goals>
                                    <goal>prepare-agent</goal>
                                </goals>
                            </execution>
                            <execution>
                                <id>agent-for-it</id>
                                <goals>
                                    <goal>prepare-agent-integration</goal>
                                </goals>
                            </execution>
                            <execution>
                                <id>jacoco-site</id>
                                <phase>post-integration-test</phase>
                                <goals>
                                    <goal>report</goal>
                                </goals>
                            </execution>
                        </executions>
                    </plugin>
                </plugins>
            </build>
        </profile>
    ...
</project>
```

A simple call with maven to run the test suite and activate jacoco class instrumentation would be:

```bash
mvn clean verify -P sonar-coverage
```

Later on the usual sonarqube run:

```bash
mvn sonar:sonar
```

---

See also:

- [example configuration from sonar itself](https://github.com/SonarSource/sonar-examples/tree/master/projects/languages/java/code-coverage/combined%20ut-it)
- [some blog entries on coverage in the sonar-blog](http://www.sonarqube.org/tag/coverage/)
- [jacoco maven-plugin](http://www.eclemma.org/jacoco/trunk/doc/maven.html)
- [older outdated config sample](http://developer.immobilienscout24.de/2013/06/maven-profile-for-combined-unit-and-integration-test-code-coverage-for-sonar/)

**Updates:**

- 2015-02-07, no need for extra failsafe config
- 2015-10-25, change phase for using the results, dont let failing integration tests miss your integration coverage
