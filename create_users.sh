#!/bin/bash

# This script sets up a new User account for new employees, based on the
# provided list of people. It creates a User's workspace with the default 
# folders: Documents, Downloads and Work. It assigns the correct user group
# to control User's access privileges. Additionally, a Welcome! file is 
# created to welcome the new employee.

# Check if the person running the script has the right permissions.
# If not, display a warning message and exit.
if [[ $EUID -ne 0 ]]; then
    echo "Unauthorized operation."
    exit 1
fi

# Input: List of names
get_users() {
    for person in "$@"; do
        local ID=$(od -An -N1 -i /dev/urandom)
        local USERNAME=$person
    done
}

## Check the passwd file to see if the user with given name
## already exists. If so, display a warning.
check_user() {
    # Loop over the input names and check if any of them already exist among users
    for name in "$@"; do
        if [[ "$(grep --fixed-strings "$name" /etc/shadow)" ]]; then
            echo "User $name already exists."
            read -p "Do you want to select a new name or add an ID? [name|id] "
            if [[ "$REPLY" == "user" ]]; then
                read -p "Input the new username. >" username 
                if ! [[ "$username" =~ ^[-[:alnum:]\._]+$ ]]; then
                    check "$username"
                else
                    echo "Invalid name format."
                    check_user "$name"
                fi

            fi

        else
            echo "User $name has been created."
        fi
    done
}

## Each user should have a random ID assigned
## Check how spaces are handled + input sanitizing
# Default folders: Documents, Downloads, Work
# Default location: /root/home/NewUser

# Create a separate file with permissions and ref in as ENV?

# Create an array with default folders
#DEF=("Documents"  "Downloads" "Work")

check_user "talia"