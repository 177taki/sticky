emitter-chrome-ext
===

Setup - only once
---

```
$ wget  http://unicode.org/Public/UNIDATA/UnicodeData.txt
$ NODE_UNICODETABLE_UNICODEDATA_TXT=/path/to/UnicodeData.txt npm install unicode -g
$ npm install yo generator-chrome-extension-kickstart -g
```

Use generator
---

```
$ mkdir my-chrome-extension && cd $_ yo chrome-extension-kickstart
```

Build
---

#### Debug Build

```
$ npm run dev:chrome
```

### Release Build

```
$ npm run build:chrome
```
