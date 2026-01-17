# config/firewall
# Configure firewall rules for routing
# policy=read,write

:log info "=== START: config-firewall ==="

:global putSuccess do={
  { [/terminal style varname-local]; :put $1 }
  :log info $1
}

{
:local configureFirewall do={
  :global putSuccess
  
  :put "=== Configuring firewall fasttrack rule ==="
  :local fasttrackId [/ip firewall filter find chain="forward" comment="fasttrack-established-related"]
  :if ($fasttrackId = "") do={
    /ip firewall filter add chain="forward" action="fasttrack-connection" hw-offload=yes connection-state="established,related" comment="fasttrack-established-related"
    $putSuccess "Added fasttrack rule"
  } else={
    /ip firewall filter set $fasttrackId comment="fasttrack-established-related" hw-offload=yes connection-state="established,related"
    $putSuccess "Updated fasttrack rule"
  }
  /ip firewall filter print where chain="forward" action="fasttrack-connection"
  :put ""

  :put "=== Configuring firewall UDP accept rule ==="
  :local udpId [/ip firewall filter find chain="forward" comment="allow-udp"]
  :if ($udpId = "") do={
    /ip firewall filter add chain="forward" action="accept" protocol="udp" comment="allow-udp"
    $putSuccess "Added UDP accept rule"
  } else={
    /ip firewall filter set $udpId comment="allow-udp" protocol="udp"
    $putSuccess "Updated UDP accept rule"
  }
  /ip firewall filter print where chain="forward" protocol="udp" action="accept"
  :put ""

  :put "=== Configuring firewall accept established/related rule ==="
  :local acceptId [/ip firewall filter find chain="forward" comment="accept-established-related"]
  :if ($acceptId = "") do={
    /ip firewall filter add chain="forward" action="accept" connection-state="established,related" comment="accept-established-related"
    $putSuccess "Added accept established/related rule"
  } else={
    /ip firewall filter set $acceptId comment="accept-established-related" connection-state="established,related"
    $putSuccess "Updated accept established/related rule"
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

}

:set putSuccess;

:log info "=== END: config-firewall ==="
