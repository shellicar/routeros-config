# config/bridge-switch
# Configure bridge mode with combo1 as bridge port
# policy=read,write

:log info "=== START: config-bridge-switch ==="

:global putSuccess do={
  { [/terminal style varname-local]; :put $1 }
  :log info $1
}

:global putDebug do={
  { :put $1 }
  :log debug $1
}

{
:local renameInterface do={
  :global putSuccess

  :put "=== Configuring combo1 interface (rename to combo1-bridge) ==="
  /interface set combo1 name="combo1-bridge" comment="Bridge port interface"
  $putSuccess "Renamed combo1 to combo1-bridge"
  :put ""
}

:local unconfigureNAT do={
  :global putSuccess
  :global putDebug

  :put "=== BEFORE: Checking NAT rules ==="
  /ip firewall nat print where chain="srcnat" and (out-interface="combo1-bridge" or out-interface="combo1-WAN") and action="masquerade"
  :put ""

  :put "=== Removing NAT masquerade rule ==="
  :local natId [/ip firewall nat find where chain="srcnat" and (out-interface="combo1-bridge" or out-interface="combo1-WAN") and action="masquerade"]
  :if ($natId != "") do={
    /ip firewall nat remove $natId
    $putSuccess "Removed NAT masquerade rule"
  } else={
    $putDebug "No NAT masquerade rule found, skipping"
  }
  :put ""

  :put "=== AFTER: Checking NAT rules ==="
  /ip firewall nat print where chain="srcnat" and (out-interface="combo1-bridge" or out-interface="combo1-WAN")
  :put ""
}

:local unconfigureWanIP do={
  :global putSuccess
  :global putDebug

  :put "=== Removing IP address from combo1-bridge (expected: no IP on combo1-bridge) ==="
  :local comboIpId [/ip address find interface="combo1-bridge"]
  :if ($comboIpId != "") do={
    /ip address remove $comboIpId
    $putSuccess "Removed IP address from combo1-bridge"
  } else={
    $putDebug "combo1-bridge has no IP address, skipping"
  }
  :put ""
}

:local configureBridgePort do={
  :global putSuccess
  
  :put "=== Adding combo1-bridge to bridge (expected: combo1-bridge in bridge ports) ==="
  :local bridgePortId [/interface bridge port find interface="combo1-bridge"]
  :if ($bridgePortId = "") do={
    /interface bridge port add bridge="bridge" interface="combo1-bridge" comment="Bridge port: combo1-bridge"
    $putSuccess "Added combo1-bridge"
  } else={
    /interface bridge port set $bridgePortId comment="Bridge port: combo1-bridge"
    $putSuccess "Updated combo1-bridge"
  }
  :put ""

  :put "=== Bridge ports (expected: combo1-bridge and other ports in bridge) ==="
  /interface bridge port print where bridge="bridge"
  :put ""

  :put "=== IP addresses (verify one line: bridge 192.168.88.1/24, combo1-bridge has no IP) ==="
  /ip address print where interface="bridge"
  /ip address print where interface="combo1-bridge"
  :put ""
}

$renameInterface
$unconfigureNAT
$unconfigureWanIP
$configureBridgePort

}

:set putSuccess
:set putDebug

:log info "=== END: config-bridge-switch ==="
