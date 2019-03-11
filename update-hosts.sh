#!/bin/bash -ue
# Christian Bryn <chr.bryn@gmail.com> 2018
# read dhcp client lease names and safely appends to /etc/hosts
# requires sudo/root privileges
#
# ----------------------------------------------------------------------------
# "THE BEER-WARE LICENSE" (Revision 42):
# <chr.bryn@gmail.com> wrote this file. As long as you retain this notice you
# can do whatever you want with this stuff. If we meet some day, and you think
# this stuff is worth it, you can buy me a beer in return.
# Christian Bryn
# ----------------------------------------------------------------------------
#

## config
hosts_file="/etc/hosts"

## flags
quiet="false"
update="false"

# fancy terminal stuff
if [ -t 1 ]; then
    exec 3>&2 2>/dev/null
    b=$( tput bold ) || true
    red=$( tput setf 4 ) || true
    green=$( tput setf 2 ) || true
    yellow=$( tput setf 6 ) || true
    t_reset=$( tput sgr0 ) || true
    exec 2>&3; exec 3>&-
fi

## functions
function print_usage {
  cat <<EOF
Safely append dhcp client lease names to /etc/hosts
This script will prompt for a sudo password.

Usage: ${0} [-hdq]
  -h    This helpful text
  -d    Delete entries previosly added.
  -u    Update/add entries.
  -q    Quiet - only print errors.

Examples:
  ${0}
  # run from cron - requires root privilegies / passwordless sudo
  ${0} -q
EOF
}

function p_err {
    # print errors
    # params: <string>
    local string="${@}"
    printf "${b:-}${red:-}>>${t_reset:-} %s\n" "${string}"
}

function p_info {
    # print info
    # params: <string>
    local string="${@}"
    [[ "${quiet}" == "false" ]] && printf "${b:-}${yellow:-}>>${t_reset:-} %s\n" "${string}"
}

function delete_entries_found {
  if ( egrep -q "^### DHCPCLIENT BEGIN ###$" "${hosts_file}" )
  then
    #p_info "ZERODATA BEGIN marker found."
    if ( ! egrep -q "^### DHCPCLIENT END ###$" "${hosts_file}" )
    then
      p_err "You have a 'DHCPCLIENT BEGIN' marker in your hosts file, but no 'DHCPCLIENT END' marker - bogus, man! Please fix to continue."
      exit 1
    fi
    p_info "Deleting old DHCPCLIENT entries. Hope you didn't manually change them."
    p_info "...need elevated privileges to do this - may prompt for sudo password"
    sudo sed -i '/^### DHCPCLIENT BEGIN ###$/,/^### DHCPCLIENT END ###$/ d' "${hosts_file}"
    p_info "OK, hopefully I removed the old ones..."
  fi
}

while getopts hduqz o
do
  case $o in
    h)
      print_usage ; exit ;;
    d)
      delete_entries_found ; exit ;;
    u)
      update="true" ;;
    q)
      update="true"
      quiet="true" ;;
  esac
done
shift $(($OPTIND-1))

[[ "${update}" != "true" ]] && { echo "No update/delete action specified!"; print_usage; exit; }

p_info "Backing up existing hosts file to /tmp/"
p_info "You should verify the results after having run this script."
cp /etc/hosts /tmp/hosts.$( date "+%s" )

delete_entries_found

p_info "Adding new entries!"

echo "### DHCPCLIENT BEGIN ###" | sudo tee -a "${hosts_file}" >/dev/null
#show dhcp leases | sed 1,2d | awk '{ print $1" "$NF }' | sudo tee -a "${hosts_file}" >/dev/null
/usr/sbin/ubnt-dhcp print-leases | sed 1,2d | awk '{ if ($6) print $1" "$6 }' | sudo tee -a "${hosts_file}" >/dev/null
echo "### DHCPCLIENT END ###" | sudo tee -a "${hosts_file}" >/dev/null

p_info "Allright. I hope this went well. Happy resolving!"
