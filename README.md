# Ophemeral

This is a web application for administration of orienteering competitions!

The aim is to create a easy to use app that solves some annoying problems with current solutions:

* No network infrastructure necessary
* Live results out of the box
* Cross-platform

Sportident readout will likely require a separate app as browser usb access is not widely supported, we'll see what the final solution ends up being!

## Local testing

`gleam run` suffices, to test the dockerimage that gets deployed run:

```sh
docker compose up --build
```

## Database stuff

### Migrations

Add new migration: 

```sh
gleam run -m feather -- new "<Name of migration>"
```
