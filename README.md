# Containerised rpmbuild
This is Docker rpmbuild container.

## Usage

If using Makefile, you can run:
```shell
make build
```

This would pick all `*.spec` files in current folder and build RPMs. Artefacts
would be dropped in `pkg/`.

## Authors
* **Marko** - [@mbevc1](https://github.com/mbevc1)
