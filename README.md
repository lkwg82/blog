this is the repository to track the blog itself and related code examples

see http://blog.lgohlke.de

# installation

```bash
CID=$(docker build . | tail -n1 | cut -d\  -f3)
docker run -v `pwd`:/jekyll -p "4000:4000" -ti $CID bundler install --path .bundler && bundler exec guard
```