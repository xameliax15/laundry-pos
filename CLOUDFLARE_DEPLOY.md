# Cloudflare Pages Build Configuration for Flutter Web

## Build Settings (paste in Cloudflare Pages dashboard):

**Framework preset:** None

**Build command:**
```bash
curl -L https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_3.10.4-stable.tar.xz -o flutter.tar.xz && tar xf flutter.tar.xz && export PATH="$PATH:$PWD/flutter/bin" && flutter config --enable-web && flutter build web --release
```

**Build output directory:**
```
build/web
```

**Root directory (important!):**
```
/
```

**Install dependencies:** 
```
(leave empty)
```

## Environment Variables:
Add these in Cloudflare Pages → Settings → Environment Variables:

```
FLUTTER_VERSION=3.10.4
```

## Important Notes:
- Do NOT deploy from `docs/` folder
- Deploy from root directory `/`
- Output is `build/web`
- Ignore Jekyll errors (add .nojekyll file to disable)
