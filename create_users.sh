#!/bin/bash
#
# Set up a new User account. The new User will belong to user 
# group with the same name. A personal workspace will be created for 
# them at /home/User with default Documents, Downloads and Work folders.
# Only the User will have RWX permissions for their own workspace. 
# A file with a welcome message will be placed in the /home/User/.


###############################################
# Authorization for executor. This shell
# script requires elevated privileges to run.
###############################################
if [[ $EUID -ne 0 ]]; then
    echo "Unauthorized operation."
    exit 1
fi


###############################################
# Validate the input list.
# Arguments:
#   A list of users.
# Returns:
#   bool:   0 - If ANY of the names in the list
#           have wrong format or already exist;
#           1 - If we can proceed with adding a
#           new User for ALL names in the list.
###############################################
process_users() {

    local person

    for person in "${@}"; do

        # Validate the input string
        # If it is not alphanumeric only, return.
        if ! [[ "$person" =~ ^[[:alnum:]]+$ ]]; then
            echo -e "Invalid name format for $person."
            echo "No special characters allowed."
            echo "Change the name and try again."
            return 0
        fi

        # Name format is correct; check the name against existing groups.
        # If User exists, return.
        if [[ -n "$(getent group $person)" ]]; then
                echo "User $person already exists."
                echo "Choose a different username."
                return 0
        fi
    done

    # Name format is correct and there is no user with the same name.
    return 1
}


###############################################
# Add new user account and workspace.
# Arguments:
#   A (validated) list of users.
# Outputs:
#   User <NAME> directory at /home/<NAME>
#   Directories: /home/<NAME>/Documents
#                /home/<NAME>/Downloads
#                /home/<NAME>/Work
#   User group <NAME>
#   welcome.txt at /home/<NAME>
###############################################
check_user() {
    # Loop over the input names and check if any of them already exist among users
    for name in "$@"; do
        
            read -p "Do you want to select a new name or add an ID? [name|id] "
            if [[ "$REPLY" == "user" ]]; then
                read -p "Input the new username. >" username 
                if ! [[ "$username" =~ ^[[:alnum:]\._]+$ ]]; then
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
