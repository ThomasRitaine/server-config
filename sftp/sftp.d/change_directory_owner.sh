#!/bin/bash

for user_dir in /home/*
do
    user=$(basename "$user_dir")
    chown -R "$user" "$user_dir/sftp_directory"
done

/usr/sbin/sshd -D
