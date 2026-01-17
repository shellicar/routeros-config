# check/routing-performance
# Display routing performance diagnostics
# policy=read

:put "=== Checking IP forwarding settings ==="
/ip settings print
:put ""

:put "=== Checking interface link speeds ==="
/interface print detail where name~"combo1-WAN|bridge"
:put ""

:put "=== Checking fast-path status (before test) ==="
/ip settings print
:put "NOTE: Run iperf3 test, then run this script again to see if counters increased"
:put ""

:put "=== Checking firewall filter rules (forward chain) ==="
/ip firewall filter print where chain="forward"
:put ""

:put "=== Checking for fast-track rules ==="
/ip firewall filter print where action="fasttrack-connection"
:put ""

:put "=== Checking for queues that might limit speed ==="
/queue simple print
/queue tree print
:put ""

:put "=== Checking CPU usage (run during iperf3 test) ==="
:put "Use: /system resource print"
:put ""
