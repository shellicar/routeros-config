# check/firewall
# Display firewall filter rule configuration
# policy=read

:put "=== Checking firewall forward chain rules ==="
/ip firewall filter print where chain="forward"
:put ""

:put "=== Checking fasttrack rule (expected: fasttrack-established-related first) ==="
:local fasttrackId [/ip firewall filter find chain="forward" comment="fasttrack-established-related"]
:if ([:len $fasttrackId] > 0) do={
    { [/terminal style varname-local]; :put "OK: Fasttrack rule exists"; }
    /ip firewall filter print where chain="forward" action="fasttrack-connection"
} else={
    { [/terminal style error]; :put "NOT FOUND: Fasttrack rule NOT found!"; }
}
:put ""

:put "=== Checking UDP accept rule (expected: allow-udp) ==="
:local udpId [/ip firewall filter find chain="forward" comment="allow-udp"]
:if ([:len $udpId] > 0) do={
    { [/terminal style varname-local]; :put "OK: UDP accept rule exists"; }
    /ip firewall filter print where chain="forward" protocol="udp" action="accept"
} else={
    { [/terminal style error]; :put "NOT FOUND: UDP accept rule NOT found!"; }
}
:put ""

:put "=== Checking accept established/related rule (expected: accept-established-related) ==="
:local acceptId [/ip firewall filter find chain="forward" comment="accept-established-related"]
:if ([:len $acceptId] > 0) do={
    { [/terminal style varname-local]; :put "OK: Accept established/related rule exists"; }
    /ip firewall filter print where chain="forward" action="accept" connection-state="established,related"
} else={
    { [/terminal style error]; :put "NOT FOUND: Accept established/related rule NOT found!"; }
}
:put ""

:put "=== Firewall rule statistics ==="
/ip firewall filter print stats where chain="forward"
:put ""
