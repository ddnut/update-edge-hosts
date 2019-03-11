update-edge-hosts
=================

By default, EdgeOS comes with dhcpd for DHCP (rather than i.e. dnsmasq).
Client lease names are not registered as DNS entries as one would expect in a home setup.
One option is to set up a full flegded bind/named instance in combination with dhcpd.
Another option is to switch to dnsmasq for DHCP as well - dnsmasq is already running acting as the local resolver, but lacks the connection to the lease pool.
This script is the horrible middle ground - since dnsmasq automatically reads _/etc/hosts_, we can populate /etc/hosts based on the leases in the pool.

Add this script to cron on the EdgeRouter to "fix" this enough to stop caring about a proper solution.

installation
------------

    root@ubnt:~# curl https://raw.githubusercontent.com/epleterte/update-edge-hosts/master/update-hosts.sh -O /usr/local/sbin/update-hosts.sh && \
                   chmod +x /usr/local/sbin/update-hosts.sh

usage
-----

    $ ./update-hosts.sh -h
    Safely append dhcp client lease names to /etc/hosts
    This script will prompt for a sudo password.
    
    Usage: ./update-hosts.sh [-hdq]
      -h    This helpful text
      -d    Delete entries previosly added.
      -u    Update/add entries.
      -q    Quiet - only print errors.
    
    Examples:
      ./update-hosts.sh
      # run from cron - requires root privilegies / passwordless sudo
      ./update-hosts.sh -q

### Run it manually

    root@ubnt:~# /usr/local/sbin/update-hosts.sh -u
    root@ubnt:~# service dnsmasq restart

### Run it in cron (as root)

    */30 * * * * /usr/local/sbin/update-hosts.sh -q -u && service dnsmasq restart >/dev/null

...you should figure out a sane cron interval. Ideally we'd detect if there was a change, but that is not implemented.
