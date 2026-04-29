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
	if ! [[ "$name" =~ ^[[:alnum:]]+$ ]]; then
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

########################################################
# 		Create default workspace.
# 1. Check if /etc/skel directory is empty and add the
#    needed directories. (I assume that normally the
#    skeleton file would already contain the premade
#    structure, instead of hardcoding it in the script.)
# 2. Create an empty welcome file in the home directory.
########################################################

if [[ -z "$(ls /etc/skel/)" ]]; then
	mkdir /etc/skel/Documents
	mkdir /etc/skel/Downloads
	mkdir /etc/skel/Work
	touch /etc/skel/welcome.txt
	"$(ls /etc/skel/)"
fi

chmod 700 /etc/skel/Documents
chmod 700 /etc/skel/Downloads
chmod 700 /etc/skel/Work
chmod 700 /etc/skel/welcome.txt

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

# Check permissions on folders


echo -e "The following user account have been created:\n" \
        "${@}"
