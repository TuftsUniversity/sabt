#!/bin/bash

# The purpose of this wrapper script is to set some environment
# variables particular to our setup on moby, prior to launching the
# FastCGI process.

export LD_LIBRARY_PATH=/tdr/bin/lib:/usr/local/lib:/usr/local/lib/mysql
export LIBRARY_PATH=/tdr/bin/lib:/usr/local/lib
export PERL5LIB=/tdr/bin/lib/perl5/5.10.1:/tdr/bin/lib/perl5/site_perl/5.10.1
export PATH=/tdr/bin/bin:/usr/local/sbin:/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/ucb:/usr/ccs/bin:/usr/proc/bin:/usr/openwin/bin

# Here's the command that actually launches the FastCGI server.
/tdr/bin/taper/script/taper_fastcgi.pl -processes 3
