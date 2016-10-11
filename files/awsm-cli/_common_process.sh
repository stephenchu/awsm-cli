#! /bin/bash

process.die() {
  printf "$1\n" >&2
  exit 1
}
