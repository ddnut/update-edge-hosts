update-edge-hosts
=================

By default, EdgeOS comes with dhcpd for DHCP (rather than i.e. dnsmasq).
Client lease names are not registered as DNS entries as one would expect.
One option is to set up a full flegded bind/named instance in combination with dhcpd.
Another option is to switch to dnsmasq for DHCP as well - dnsmasq is already running acting as the local resolver, but lacks the connection to the lease pool.
This script is the horrible middle ground - since dnsmasq automatically reads _/etc/hosts_, we can populate /etc/hosts based on the leases in the pool.

Add this script to cron on the EdgeRouter to "fix" this enough to stop caring about a proper solution.
