# config/wan-only
# Configure router mode with WAN interface, no NAT
# policy=read,write

:log info "=== START: config-wan-only ==="

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
  :put "=== Configuring combo1 interface (rename to combo1-WAN) ==="
  /interface set combo1 name="combo1-WAN" comment="WAN interface"
  $putSuccess "Renamed combo1 to combo1-WAN"
  :put ""
}

:local removeFromBridge do={
  :global putSuccess
  :global putDebug
  :put "=== Removing combo1-WAN from bridge (expected: combo1-WAN NOT in bridge) ==="
  :local bridgePortId [/interface bridge port find interface="combo1-WAN"]
  :if ($bridgePortId != "") do={
    /interface bridge port remove $bridgePortId
    $putSuccess "Removed combo1-WAN from bridge"
  } else={
    $putDebug "combo1-WAN is not in bridge, skipping"
  }
  :put ""

  :put "=== Verifying bridge ports (expected: combo1-WAN NOT listed) ==="
  /interface bridge port print where interface="combo1-WAN"
  :put ""
}

:local configureDHCP do={
  :global putSuccess
  :put "=== Configuring DHCP pool (expected: dhcp-pool-bridge range 192.168.88.100-192.168.88.199) ==="
  :local poolId [/ip pool find name="dhcp-pool-bridge"]
  :if ($poolId = "") do={
    /ip pool add name="dhcp-pool-bridge" ranges="192.168.88.100-192.168.88.199" comment="DHCP address pool for bridge interface"
    $putSuccess "Added DHCP pool dhcp-pool-bridge"
  } else={
    /ip pool set $poolId ranges="192.168.88.100-192.168.88.199" comment="DHCP address pool for bridge interface"
    $putSuccess "Updated DHCP pool dhcp-pool-bridge range"
  }
  /ip pool print where name="dhcp-pool-bridge"
  :put ""

  :put "=== Configuring DHCP server (expected: dhcp-bridge on bridge interface) ==="
  :local dhcpServerId [/ip dhcp-server find interface="bridge"]
  :if ($dhcpServerId = "") do={
    /ip dhcp-server add interface="bridge" address-pool="dhcp-pool-bridge" name="dhcp-bridge" comment="DHCP server for bridge interface"
    $putSuccess "Added DHCP server dhcp-bridge"
  } else={
    /ip dhcp-server set $dhcpServerId comment="DHCP server for bridge interface"
    $putSuccess "Updated DHCP server dhcp-bridge"
  }
  /ip dhcp-server print where interface="bridge"
  :put ""

  :put "=== Configuring DHCP network (expected: 192.168.88.0/24 gateway 192.168.88.1) ==="
  :local dhcpNetworkId [/ip dhcp-server network find address="192.168.88.0/24"]
  :if ($dhcpNetworkId = "") do={
    /ip dhcp-server network add address="192.168.88.0/24" gateway="192.168.88.1" comment="DHCP network configuration for bridge interface"
    $putSuccess "Added DHCP network 192.168.88.0/24"
  } else={
    /ip dhcp-server network set $dhcpNetworkId comment="DHCP network configuration for bridge interface"
    $putSuccess "Updated DHCP network 192.168.88.0/24"
  }
  /ip dhcp-server network print where address="192.168.88.0/24"
  :put ""
}

:local configureWanIP do={
  :global putSuccess
  :put "=== Configuring IP address on combo1-WAN (expected: 192.168.200.2/24) ==="
  :local wanIpId [/ip address find interface="combo1-WAN"]
  :if ($wanIpId = "") do={
    /ip address add address="192.168.200.2/24" interface="combo1-WAN" comment="WAN interface IP address"
    $putSuccess "Added IP address 192.168.200.2/24 to combo1-WAN"
  } else={
    /ip address set $wanIpId address="192.168.200.2/24" comment="WAN interface IP address"
    $putSuccess "Updated IP address on combo1-WAN to 192.168.200.2/24"
  }
  /ip address print where interface="combo1-WAN"
  :put ""

  :put "=== Configuring IP address on bridge (expected: 192.168.88.1/24) ==="
  :local bridgeIpId [/ip address find interface="bridge"]
  :if ($bridgeIpId = "") do={
    /ip address add address="192.168.88.1/24" interface="bridge" comment="Bridge interface IP address"
    $putSuccess "Added IP address 192.168.88.1/24 to bridge"
  } else={
    /ip address set $bridgeIpId address="192.168.88.1/24" comment="Bridge interface IP address"
    $putSuccess "Updated IP address on bridge to 192.168.88.1/24"
  }
  /ip address print where interface="bridge"
  :put ""
}

:local configureWanRoute do={
  :global putSuccess
  :put "=== Configuring default route (expected: 0.0.0.0/0 gateway 192.168.200.1) ==="
  :local defaultRouteId [/ip route find dst-address="0.0.0.0/0"]
  :if ($defaultRouteId = "") do={
    /ip route add dst-address="0.0.0.0/0" gateway="192.168.200.1" comment="Default route to gateway"
    $putSuccess "Added default route 0.0.0.0/0 -> 192.168.200.1"
  } else={
    /ip route set $defaultRouteId gateway="192.168.200.1" comment="Default route to gateway"
    $putSuccess "Updated default route gateway to 192.168.200.1"
  }
  /ip route print where dst-address="0.0.0.0/0"
  :put ""
}

:local unconfigureNAT do={
  :global putSuccess
  :global putDebug
  :put "=== BEFORE: Checking NAT rules (expected: no NAT rules on combo1-WAN) ==="
  /ip firewall nat print where chain="srcnat" and out-interface="combo1-WAN" and action="masquerade"
  :put ""

  :put "=== Removing NAT masquerade rule (if present) ==="
  :local natId [/ip firewall nat find where chain="srcnat" and out-interface="combo1-WAN" and action="masquerade"]
  :if ($natId != "") do={
    /ip firewall nat remove $natId
    $putSuccess "Removed NAT masquerade rule from combo1-WAN"
  } else={
    $putDebug "No NAT masquerade rule found on combo1-WAN, skipping"
  }
  :put ""

  :put "=== AFTER: Verifying NAT rules (expected: no NAT rules on combo1-WAN) ==="
  /ip firewall nat print where chain="srcnat" and out-interface="combo1-WAN" and action="masquerade"
  :put ""
}

$renameInterface
$removeFromBridge
$unconfigureNAT
$configureDHCP
$configureWanIP
$configureWanRoute

}

:set putSuccess;
:set putDebug;

:log info "=== END: config-wan-only ==="
