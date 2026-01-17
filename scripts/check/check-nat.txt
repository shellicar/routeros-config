# check/nat
# Display NAT masquerade rule configuration and connection tracking status
# policy=read

:put "=== Checking NAT masquerade rule configuration ==="
/ip firewall nat print where chain="srcnat" and out-interface="combo1-WAN" and action="masquerade"
:put ""
:local natRuleCount [:len [/ip firewall nat find where chain="srcnat" and out-interface="combo1-WAN" and action="masquerade"]]
:if ($natRuleCount > 0) do={
    { [/terminal style varname-local]; :put "OK: NAT masquerade rule exists"; }
} else={
    { [/terminal style error]; :put "NOT FOUND: NAT masquerade rule NOT found!"; }
}
:put ""

:put "=== Checking active connections (connection tracking table) ==="
:local connectionCount [/ip firewall connection print count-only]
:put ("Active connections: " . $connectionCount)
:put ""
:if ($connectionCount > 0) do={
    { [/terminal style varname-local]; :put "OK: Connection tracking table has entries - NAT is processing traffic"; }
    :put ""
    :put "=== Sample connection entries (showing NAT'd connections) ==="
    :put "Source IP will be NAT'd to combo1-WAN IP (192.168.200.2):"
    /ip firewall connection print detail
    :put ""
    :put "Look for connections where:"
    :put "- src-address is 192.168.88.x (internal network)"
    :put "- nat-src-address is 192.168.200.2 (WAN IP - this confirms NAT)"
    :put ""
} else={
    { [/terminal style syntax-meta]; :put "WARNING: No active connections - NAT rule exists but no traffic has been processed yet"; }
    :put "Generate some traffic (ping, web browsing) to see connections appear"
}
:put ""

:put "=== Interface traffic statistics ==="
:put "combo1-WAN (outbound - NAT'd traffic):"
/interface print stats where name="combo1-WAN"
:put ""
:put "bridge (inbound - source of NAT'd traffic):"
/interface print stats where name="bridge"
:put ""
:put "If combo1-WAN TX bytes > 0 and matches bridge RX pattern, NAT is processing traffic"
:put ""

:put "=== Verification Methods Summary ==="
:put "1. NAT rule exists: Check above - should show masquerade rule for combo1-WAN"
:put "2. Connection tracking enabled: Required for NAT to work"
:put "3. Active connections: Connection table shows NAT'd connections"
:put "4. Interface counters: Traffic flow confirms NAT is active"
:put ""
:put "=== To Test NAT ==="
:put "1. Run this script BEFORE generating traffic (to see baseline)"
:put "2. Generate traffic from a device on 192.168.88.0/24 network"
:put "   (ping, web browsing, etc.)"
:put "3. Run this script AGAIN (should show active connections)"
:put "4. Check connection entries - look for nat-src-address=192.168.200.2"
:put ""
