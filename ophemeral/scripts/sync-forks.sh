#!/bin/sh

git clone https://github.com/cheesemans/feather.git /tmp/feather --quiet
git clone https://github.com/cheesemans/argus.git /tmp/argus --quiet

rm -rf /tmp/feather/.git*
rm -rf /tmp/argus/.git*

cp -r /tmp/feather ../external --force
cp -r /tmp/argus ../external --force

rm -rf /tmp/feather /tmp/argus

changed_files=$(git diff --name-only ../external)

if [ -n "$changed_files" ]; then
  echo "Forks have been updated, stage the following files and attempt to commit again:" >&2
  echo "$changed_files" >&2
  exit 1
fi
