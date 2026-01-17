# check/fastpath-config
# Display fastpath configuration and hardware offloading status
# policy=read

:put "=== Checking if hardware offloading is enabled ==="
/interface print detail where name~"combo1-WAN|bridge"
:put "Look for 'fast-path' or 'hw-offload' in the output"
:put ""

:put "=== Checking bridge configuration ==="
/interface bridge print detail
:put ""

:put "=== Checking if interfaces are in bridge (combo1-WAN should NOT be in bridge for routing) ==="
/interface bridge port print
:put ""

:put "=== Checking for CRS-specific hardware offload settings ==="
/interface ethernet print detail where name~"combo1"
:put ""

:put "=== Current fast-path status ==="
/ip settings print
:put ""

:put "=== Checking firewall fast-track rules (must be first in forward chain) ==="
/ip firewall filter print where chain="forward" and action="fasttrack-connection"
:put ""

:put "=== Full forward chain (to verify rule order) ==="
/ip firewall filter print where chain="forward"
:put ""

:put "=== Checking if there are any firewall rules that could prevent fast-path ==="
/ip firewall filter print where chain="forward" and (action="drop" or action="reject" or log=yes)
:put ""

:put "=== Interface details for combo1-WAN ==="
/interface print detail where name="combo1-WAN"
:put ""

:put "=== Bridge interface details ==="
/interface print detail where name="bridge"
:put ""

:put "NOTE: For CRS106, fast-path typically only works for:"
:put "1. Same switch chip traffic"
:put "2. Bridge/L2 switching"
:put "3. NOT for routing between different networks"
:put ""
:put "But check the above to ensure configuration isn't blocking it."
