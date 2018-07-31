# Purpose
docker-backup is a script for backuping running docker containers, docker images and docker volumens

# Usage

```
USAGE: docker-backup.sh [-a|-c|-i|-v]
Long format options: [--all|--containers|--images|--volumes]

Options:
 -a | --all perform full backup, this is equal to -c -i -v
 -c | --containers perform backup of running containers
 -i | --images perform images backup from running containers
 -v | --volumes perform volumes backup from running containers
```
