# Containerised rpmbuild
This is Docker rpmbuild container.

## Usage

### Makefile

You can simply run:
```shell
make build
```

This would pick all `*.spec` files in current folder and build RPMs. Artefacts
would be dropped in `pkg/`. All files in folder `src/`, if exists are used as
RPM sources when building.

### Manual

It can also be used by manually running Docker:
```shell
docker pull mbevc1/rpmbuild

docker run --rm -it -v $(pwd):/src -e VERSION=1.0 -e RELEASE=1 mbevc1/rpmbuild <some>.spec <output_path>/
```

## Authors
* **Marko Bevc** - [@mbevc1](https://github.com/mbevc1)
