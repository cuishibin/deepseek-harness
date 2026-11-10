# Docker images

This directory ships two container builds for the repository root:

- `Dockerfile.dev` keeps the full source tree, workspace dependencies, and built artifacts so the container can run `pnpm dsh web` exactly like the repository docs describe.
- `Dockerfile.prod` builds from source, deploys the runtime closure with `pnpm deploy`, and launches the built CLI directly for a smaller runtime image.
- The dev image also pre-activates the workspace-pinned pnpm version during `docker build`, so container startup does not re-download pnpm through Corepack.
- Both Dockerfiles use a BuildKit-backed pnpm store cache, and `.dockerignore` excludes clearly non-runtime local data such as `docker/data/`, which reduces repeated build time without dropping files that the repository build reads.

## Choose an image

- Use the dev image when you want repository-faithful startup, the exact `pnpm dsh web` entry, or easier debugging inside the checkout.
- Use the prod image when you want a smaller image that runs the built Web service without keeping the whole workspace tree.

## Common environment

Both entrypoints honor the same variables:

- `DEEPSEEK_API_KEY`: provider credential for normal Web usage.
- `DSH_HOME`: persisted DSH home directory. Defaults to `/data/dsh-home` in the image.
- `DSH_BIND_HOST`: explicit concrete bind address. When omitted, the entrypoint uses the container's first `hostname -i` address because `dsh web` rejects `0.0.0.0`.
- `DSH_PORT`: listener port. Defaults to `3080`.
- `DSH_TRUSTED_HOSTS`: comma-separated host list passed as repeated `--trusted-host` flags. Defaults to `localhost,127.0.0.1`.
- `DSH_PUBLIC_URL`: optional `--public-url` value for reverse-proxy deployments.
- `DSH_TLS_CERT` and `DSH_TLS_KEY`: optional TLS pair; either set both or neither.
- `DSH_NO_OPEN`: set to `0` to allow browser opening. The default `1` adds `--no-open`.
- `DSH_EXTRA_ARGS`: optional extra CLI flags, split by the shell and appended after the standard flags.

## Build

Build the dev image:

```sh
docker build \
  --build-arg DSH_CLIENT_COMMIT_HASH="$(git rev-parse HEAD)" \
  -f docker/Dockerfile.dev \
  -t dsh-web-dev .
```

```powershell
docker build `
  --build-arg DSH_CLIENT_COMMIT_HASH="$(git rev-parse HEAD)" `
  -f docker/Dockerfile.dev `
  -t dsh-web-dev .
```

Build the prod image:

```sh
docker build \
  --build-arg DSH_CLIENT_COMMIT_HASH="$(git rev-parse HEAD)" \
  -f docker/Dockerfile.prod \
  -t dsh-web-prod .
```

On Windows PowerShell, the same flag looks like this:

```powershell
docker build `
  --build-arg DSH_CLIENT_COMMIT_HASH="$(git rev-parse HEAD)" `
  -f docker/Dockerfile.prod `
  -t dsh-web-prod .
```

## Run

Run the dev image from the repository root:

```sh
docker run --rm -it \
  -p 3080:3080 \
  -e DEEPSEEK_API_KEY=your-key \
  -e DSH_HOME=/data/dsh-home \
  -e DSH_PUBLIC_URL=http://localhost:3080 \
  -v dsh-home:/data/dsh-home \
  dsh-web-dev
```

```powershell
docker run --rm -it `
   -p 3080:3080 `
   -e DEEPSEEK_API_KEY=your-key `
   -e DSH_HOME=/data/dsh-home `
   -e DSH_PUBLIC_URL=http://localhost:3080 `
   -v "$(pwd)/data/dsh-web-dev/dsh-home:/data/dsh-home" `
   -v "$(pwd)/data/dsh-web-dev/workspace:/workspace" `
   dsh-web-dev
```


Run the prod image with a separate workspace mount:

```sh
docker run --rm -it \
  -p 3080:3080 \
  -e DEEPSEEK_API_KEY=your-key \
  -e DSH_HOME=/data/dsh-home \
  -e DSH_PUBLIC_URL=http://localhost:3080 \
  -v "$(pwd)/data/dsh-web-prod/dsh-home:/data/dsh-home" \
  -v "$(pwd)/data/dsh-web-prod/workspace:/workspace" \
  dsh-web-prod
```

```powershell
docker run --rm -it `
  -p 3080:3080 `
  -e DEEPSEEK_API_KEY=your-key `
  -e DSH_HOME=/data/dsh-home `
  -e DSH_PUBLIC_URL=http://localhost:3080 `
  -v "$(pwd)/data/dsh-web-prod/dsh-home:/data/dsh-home" `
  -v "$(pwd)/data/dsh-web-prod/workspace:/workspace" `
  dsh-web-prod
```

## Notes

- The dev image starts in `/app`, which is the repository root inside the container. That keeps `pnpm dsh web` aligned with the documented source-launch flow.
- The prod image starts in `/workspace`, while the deployed runtime lives under `/opt/dsh`. Mount a project or checkout there when you want the Web profile to use a specific workspace root.
- Both images expose port `3080`; change the container port with `DSH_PORT` if needed.
- Build speed usually improves most after the first successful build: the cached base layers and the shared pnpm store remove much of the repeated download cost, but `pnpm run build` is still a full repository build.

## 初始登录token存储位置

```text
- /opt/dsh/data/dsh-web-dev/dsh-home/.credentials.yaml

[root@localhost dsh-home]# more .credentials.yaml
version: 1
records:
  client-connection/browser-session:
    kind: grant
    payload:
      version: 1
      secret: 1RoxPQ5YYPCg5lON0aAtws2AQzLGhkywYF57a-_RHcE

secret: 并不是初始登录token，而是登录后获取的token，用于后续请求

http://10.12.1.238:3080/?token=1RoxPQ5YYPCg5lON0aAtws2AQzLGhkywYF57a-_RHcE
```
