---
title: "lint-maven-plugin - check your pom.xml"
date: 2013-09-09T14:00:02Z
lastmod: 2013-09-09T14:00:02Z
draft: false
tags: ["maven", "lint", "quality"]
---

We know for each and everything there are some *Do's* and many *Don'ts*. This is about recommendations on your [pom.xml](http://maven.apache.org/guides/introduction/introduction-to-the-pom.html) of your maven project.

Just try this:

```bash
$ mvn com.lewisd:lint-maven-plugin:check
[INFO] Scanning for projects...
[INFO]
[INFO] ------------------------------------------------------------------------
[INFO] Building Maven POM lint plugin 0.0.9-SNAPSHOT
[INFO] ------------------------------------------------------------------------
[INFO]
[INFO] --- lint-maven-plugin:0.0.8:check (default-cli) @ lint-maven-plugin ---
[INFO] Writing summary report
[INFO] [LINT] Completed with 3 violations
[INFO] [LINT] OSSIssueManagementSectionRule: missing section : 0:0 : /home/lars/development/workspaces/sonar/lint-maven-plugin/pom.xml
[INFO] [LINT] ExecutionId: Executions must specify an id : 346:40 : /home/lars/development/workspaces/sonar/lint-maven-plugin/pom.xml
[INFO] [LINT] OSSContinuousIntegrationManagementSectionRule: missing section : 0:0 : /home/lars/development/workspaces/sonar/lint-maven-plugin/pom.xml
[INFO] Writing xml report
[INFO] ------------------------------------------------------------------------
[INFO] BUILD FAILURE
[INFO] ------------------------------------------------------------------------
[INFO] Total time: 2.678s
[INFO] Finished at: Mon Sep 09 02:00:32 CEST 2013
[INFO] Final Memory: 11M/267M
[INFO] ------------------------------------------------------------------------
[ERROR] Failed to execute goal com.lewisd:lint-maven-plugin:0.0.8:check (default-cli) on project lint-maven-plugin: [LINT] Violations found. For more details, see error messages above, or results in /home/lars/development/workspaces/sonar/lint-maven-plugin/target/maven-lint-result.xml -> [Help 1]
[ERROR]
[ERROR] To see the full stack trace of the errors, re-run Maven with the -e switch.
[ERROR] Re-run Maven using the -X switch to enable full debug logging.
[ERROR]
[ERROR] For more information about the errors and possible solutions, please read the following articles:
[ERROR] [Help 1] http://cwiki.apache.org/confluence/display/MAVEN/MojoFailureException
```

## List of rules

You can see the list of supported rules with:

```bash
$ mvn com.lewisd:lint-maven-plugin:list
```

- **DotVersionProperty**: The convention is to specify properties used to hold versions as "some.library.version",or some-library.version, but never some-library-version or some.library-version.
- **DuplicateDep**: Multiple dependencies, in `<dependencies>` or `<managedDependencies>`, with the same co-ordinatesare reduntant, and can be confusing. If they have different versions, they can leadto unexpected behaviour.
- **ExecutionId**: Executions should always specify an id, so they can be overridden in child modules,and uniquely identified in build logs.
- **GAVOrder**: Maven convention is that the groupId, artifactId, and version elements be listed inthat order. Other elements with short, simple content, such as type, scope, classifier,etc, should be before elements with longer content, such as configuration, executions,and exclusions, otherwise they can be easily missed, leading to confusion
- **OSSContinuousIntegrationManagementSectionRule**: For better understanding the project a link to the used integration system helps usersto trust.
- **OSSDevelopersSectionRule**: The users/developers need to know where to get active bugs and to report new onesto.
- **OSSInceptionYearRule**: For better understanding the project the inception year of your project is required.
- **OSSIssueManagementSectionRule**: The users/developers need to know where to get active bugs and to report new onesto.
- **OSSLicenseSectionRule**: Each project should be licensed under a specific license so the terms of usage areclear.
- **OSSUrlSectionRule**: For better understanding the project a link to your project is required.
- **ProfileOnlyAddModules**: Profiles who's ids match the pattern with-.* must only add modules to the reactor.
- **RedundantDepVersion**: Dependency versions should be set in one place, and not overridden without changingthe version. If, for example, `<dependencyManagement>` sets a version, and `<dependencies>`somewhere overrides it, but with the same version, this can make version upgradesmore difficult, due to the repetition.
- **RedundantPluginVersion**: Plugin versions should be set in one place, and not overridden without changing theversion. If, for example, `<pluginManagement>` sets a version, and `<plugins>` somewhereoverrides it, but with the same version, this can make version upgrades more difficult,due to the repetition.
- **VersionProp**: The ${version} property is deprecated. Use ${project.version} instead.

---

The source can be found on github [https://github.com/lewisd32/lint-maven-plugin](https://github.com/lewisd32/lint-maven-plugin) currently version 0.0.8 is online.

Contributions are welcome and will be integrated very fast, thanks to Lewis!

