# config/firewall
# Configure firewall rules for routing
# policy=read,write

:log info "=== START: config-firewall ==="

:global configureFirewall do={
    :put "=== Configuring firewall fasttrack rule ==="
    :local fasttrackId [/ip firewall filter find chain="forward" comment="fasttrack-established-related"]
    :if ([:len $fasttrackId] = 0) do={
        /ip firewall filter add chain="forward" action="fasttrack-connection" hw-offload=yes connection-state="established,related" comment="fasttrack-established-related"
        :put "Added fasttrack rule"
        :log info "Added fasttrack rule"
    } else={
        /ip firewall filter set $fasttrackId comment="fasttrack-established-related" hw-offload=yes connection-state="established,related"
        :put "Updated fasttrack rule"
        :log info "Updated fasttrack rule"
    }
    /ip firewall filter print where chain="forward" action="fasttrack-connection"
    :put ""

    :put "=== Configuring firewall UDP accept rule ==="
    :local udpId [/ip firewall filter find chain="forward" comment="allow-udp"]
    :if ([:len $udpId] = 0) do={
        /ip firewall filter add chain="forward" action="accept" protocol="udp" comment="allow-udp"
        :put "Added UDP accept rule"
        :log info "Added UDP accept rule"
    } else={
        /ip firewall filter set $udpId comment="allow-udp" protocol="udp"
        :put "Updated UDP accept rule"
        :log info "Updated UDP accept rule"
    }
    /ip firewall filter print where chain="forward" protocol="udp" action="accept"
    :put ""

    :put "=== Configuring firewall accept established/related rule ==="
    :local acceptId [/ip firewall filter find chain="forward" comment="accept-established-related"]
    :if ([:len $acceptId] = 0) do={
        /ip firewall filter add chain="forward" action="accept" connection-state="established,related" comment="accept-established-related"
        :put "Added accept established/related rule"
        :log info "Added accept established/related rule"
    } else={
        /ip firewall filter set $acceptId comment="accept-established-related" connection-state="established,related"
        :put "Updated accept established/related rule"
        :log info "Updated accept established/related rule"
    }
    /ip firewall filter print where chain="forward" action="accept" connection-state="established,related"
    :put ""

    :put "=== Ordering rules (1=fasttrack, 2=UDP, 3=accept established/related) ==="
    :local fasttrackId [/ip firewall filter find chain="forward" comment="fasttrack-established-related"]
    :local udpId [/ip firewall filter find chain="forward" comment="allow-udp"]
    :local acceptId [/ip firewall filter find chain="forward" comment="accept-established-related"]
    
    /ip firewall filter move $fasttrackId 1
    /ip firewall filter move $udpId 2
    /ip firewall filter move $acceptId 3
    :put ""

    :put "=== Verifying rule order (expected: 0=dummy, 1=fasttrack, 2=UDP, 3=accept established/related) ==="
    /ip firewall filter print where chain="forward"
    :put ""
}

$configureFirewall

:set configureFirewall;

:log info "=== END: config-firewall ==="
