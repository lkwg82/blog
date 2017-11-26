this is the repository to track the blog itself and related code examples

see http://blog.lgohlke.de

# installation

run 
```bash
./docker-run.sh
```

clean
```bash
rm -rf .bundle .bundler _site
```

test
```bash
./docker-test.sh
``` 

use these gems: https://pages.github.com/versions.json
see https://github.com/github/pages-gem
update to latest github gems
```bash
./docker-run.sh bundle update
```
