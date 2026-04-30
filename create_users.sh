#!/bin/bash
#
# Set up a new User account. Takes a list of names in an alphanumeric format
# ONLY. No special characters are allowed. Creates default workspace folders
# and a welcome message.


########################################################
# 		User authorization.
# This shell script requires elevated privileges to run.
########################################################

if [[ $EUID -ne 0 ]]; then
	echo "Unauthorized operation. Run as root."
	exit 1
fi

########################################################
# 		Input validation.
# Processes the input names and adds them to two arrays.
# Each array is checked separately to provide a single
# feedback on input errors. If any of the arrays have
# more than one element, exit the script.
########################################################

for name in "${@}"; do
	# Invalid name format
	if ! [[ "$name" =~ ^[[:alpha:]][[:alnum:]]+$ ]]; then
		invalid_input+="${name} "
	else
		# Duplicate user
		if [[ -n "$(getent group "$name")" ]]; then
			duplicates+="${name} "
		fi
	fi
done

# Display a list of users with invalid names, if any exist.

if [[ "${#invalid_input[@]}" -gt 0 ]]; then
	echo -e "Error: Invalid user name(s): ${invalid_input[*]}.\n"\
			"Names may not contain any special characters."
fi

# Display a list of duplicate usernames, if any exist.

if [[ "${#duplicates[@]}" -gt 0 ]]; then
    # shellcheck disable=SC2140
	echo -e "Error: Existing user name(s): ${duplicates[*]}.\n"\
			"Choose a name that's not in the following list:\n"\
			"$(ls /home/)"""
fi

# If any of those lists contain elements, exit.

if [[ "${#invalid_input[@]}" -gt 0 || "${#duplicates[@]}" -gt 0 ]]; then
	exit 1
fi

#echo "-----------------> START CLEAN-UP <-------------------"
#users="$(ls /home/)"
#for rem in ${users[@]}; do
#	if [[ ${rem} != "tails" ]]; then
#		userdel -r "${rem}"
#	fi
#done
#
#rm /home/tails/user_access
#
#rmdir /etc/skel/Documents
#rmdir /etc/skel/Downloads
#rmdir /etc/skel/Work
#rm -r /etc/skel/welcome.txt
#echo "------------------> END CLEAN-UP <--------------------"

########################################################
# 			Create default workspace.
# Loop over an array with names for default folders.
# Check if the folders exist, if not, create them.
# Repeat the process for the welcome file. Set 700
# permissions for the entire directory and its contents.
########################################################

# Create default folders if they don't exist

defaults=(Documents Downloads Work)

for m in "${defaults[@]}"; do
	file -d -E /etc/skel/"${m}" >/dev/null
	if [[ $? == 1 ]]; then
		mkdir /etc/skel/"${m}"
	fi
done

# Create a welcome file, if it doesn't exist

if [[ ! -e "/etc/skel/welcome.txt" ]]; then
	touch /etc/skel/welcome.txt
fi

# Set correct permissions for dir and all contents
chmod -R 700 /etc/skel/

########################################################
# 			Add users.
# 1. Create a root-access file to store the initial,
#    generated passwords.
# 2. Add a new user, with following options:
# 	- password expired (user must change to own
#         password on first login
#       - day counts related to user password change
#       - encrypting the initial password
#       - creating home directory
#       - adding user name to welcome message
########################################################

if ! [[ -e /home/tails/user_access ]]; then
	touch /home/tails/user_access
	chmod 700 /home/tails/user_access
fi

# Add new users.
for name in "${@}"; do
	temp_pass=$(od -An -t x8 -N8 /dev/urandom)
	echo "$name" "$temp_pass" >> /home/tails/user_access
	useradd --badname \
			-f 0 \
	        -K PASS_MAX_DAYS=90 \
	    	-K PASS_MIN_DAYS=7 \
            -K PASS_WARN_AGE=14 \
			-K UMASK=0022 \
			-m \
            -p "$(openssl passwd -6 "${temp_pass}")" \
            "$name"
	passwd -e "${name}"
	echo "User $name created."
	echo "Välkommen ${name^}" >> /home/"${name}"/welcome.txt
	echo "${@}" >> /home/"${name}"/welcome.txt
done

if [[ "${#@}" -gt 0 ]]; then
	echo -e "The following user accounts have been created:\n"\
    "${@}"
else
	echo "No new users created."
fi
