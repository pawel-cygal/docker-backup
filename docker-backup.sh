#!/bin/bash
#####################################################################################
# Author: Pawel Cygal
# Maintainer: Pawel Cygal
# email: destine@poczta.fm
# date: 2018-05-01
# description: this script perform backup of docker containers and docker volumes
#####################################################################################

config_file_path="docker-backup.cfg"
date_time=$(date)

# Function print output in nice way
function _nice_output(){
    printf "\033[0;36m%s\033[m\n" "$1"
}


# Function print output in green color for success
function _success(){
    printf "\033[0;32m%s\033[0m\n" "%1"
}


# Function print output in red color for errors
function _fail(){
    printf "\033[0;31m%s\033[0m\n" "$1" 1>&2
}


# Function read configuration from config file "docker-backup.cfg"
function read_config(){
    if [ -f "${config_file_path}" ]; then
        source "${config_file_path}"
        _success "Configurtaion Loaded successful [ OK ]"
    else
        _fail "ERR: Cannot load docker-backup.cfg"
        exit 1
    fi
}


# Function print help for script
function usage(){
    _nice_output "USAGE: $0 [-a|-c|-i|-v]"
    _nice_output "Long format options: [--all|--containers|--images|--volumes]" 1>&2;
    _nice_output ""
    _nice_output "Options:"
    _nice_output " -a | --all perform full backup, this is equal to -c -i -v"
    _nice_output " -c | --containers perform backup of running containers"
    _nice_output " -i | --images perform images backup from running containers"
    _nice_output " -v | --volumes perform volumes backup from running containers"
    exit 1;
}


# Function is backuping docker images from running container
# this is using docker save command
function backup_images(){
    for i in $(docker inspect --format='{{.Name}}' $(docker ps -q) | cut -f2 -d\/)
    do
        container_name="${i}"
        _nice_output "Container Name: ${container_name} - "
        container_image=$(docker inspect --format='{{.Config.Image}}' "${container_name}")
        container_image_wos=$(echo ${container_image} | sed 's/\//-/g')
        _nice_output "Started From Image: ${container_image} -"
        mkdir -p "${backup_path}/${container_image}"
        save_file="${backup_path}/${container_image}/${container_image_wos}.tar"

        if docker save -o "${save_file}" "${container_image}"; then
            exec 3>&1 # save stdout as fd 3
            exec >> "${backup_path}/${container_image}/IMAGE.txt"
            printf "%s\n" "Backup has been made via docker save command."
            printf "%s\n" "Date: ${date_time}"
            printf "%s\n" "From Container Name: ${container_name}"
            printf "%s\n" "Container Image Name: ${container_image}"
            exec >&3 3>&- # restore stdout and close fd 3

            _success "Image backup status [ OK ]"
        else
            _fail "ERR: Somthing went wrong!!!"
        fi
    done
}


# Function is backuping docker volumes from running containers
function backup_volumes(){
    for i in $(docker inspect --format='{{.Name}}' $(docker ps -q) | cut -f2 -d\/)
    do
        container_name="${i}"
        _nice_output "$container_name - "
        mkdir -p "${backup_path}/${container_name}"
        container_image=$(docker inspect --format='{{.Config.Image}}' "${container_name}")

        if docker run --rm --volumes-from "${container_name}" \
            -v "${backup_path}":/backup \
            -e TAR_OPTS="$tar_opts" "${container_image}" backup \
            "${container_name}/${container_name}-volume.tar.gz"
        then
            exec 3>&1 # save stdout as fd 3
            exec >> "${backup_path}/${container_name}/VOLUME.txt"
            printf "%s\n" "Volume backup."
            printf "%s\n" "Date: ${date_time}"
            printf "%s\n" "From Container Name: ${container_name}"
            exec >&3 3>&- # restore stdout and close fd 3

            _success "Volume backup status [ OK ]"
        else
            _fail "ERR: Somthing went wrong!!!"
        fi
    done
}


# Function is backuping running docker container
# this is usning docker export command
function backup_container(){
    for i in $(docker inspect --format='{{.Name}}' $(docker ps -q) | cut -f2 -d\/)
    do
        container_name="${i}"
        _nice_output "${container_name} - "
        container_image=$(docker inspect --format='{{.Config.Image}}' "${container_name}")
        mkdir -p "${backup_path}/${container_name}"
        save_file="${backup_path}/${container_name}/${container_name}-container.tar"

        if docker export -o "${save_file}" "${container_name}"; then
            exec 3>&1 # save stdout as fd 3
            exec >> "${backup_path}/${container_name}/CONTAINER.txt"
            printf "%s\n" "Backup has been made via docker export command."
            printf "%s\n" "Date: ${date_time}"
            printf "%s\n" "From Container Name: ${container_name}"
            exec >&3 3>&- # restore stdout and close fd 3

            _success "Container backup status [ OK ]"
        else
            _fail "ERR: Somthing went wrong!!!"
        fi
    done
}


# Function run all backups functions
function all(){
    backup_images
    backup_volumes
    backup_container
}


# Main program
read_config

if [[ "$#" -lt 1 ]]; then
      _fail "ERR: Script reqiured at least one parameters!"
      usage
      exit 666
fi

OPTSPEC="aciv-:"
while getopts "$OPTSPEC" OPTCHAR; do
    case "${OPTCHAR}" in
        a)
            all
        ;;
        c)
            backup_container
        ;;
        i)
            backup_images
        ;;
        v)
            backup_volumes
        ;;
        -)
            case "${OPTARG}" in
                all)
                    all
                ;;
                containers)
                    backup_container
                ;;
                images)
                    backup_images
                ;;
                volumes)
                    backup_volumes
                ;;
                *)
                    usage
                ;;
            esac
    esac
done
