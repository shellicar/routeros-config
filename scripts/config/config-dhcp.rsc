# config/dhcp
# Configure DHCP pool, server, and network for bridge interface
# policy=read,write

:log info "=== START: config-dhcp ==="

:global putSuccess do={
  { [/terminal style varname-local]; :put $1 }
  :log info $1
}

:global configureDHCP do={
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

$configureDHCP

:set configureDHCP;
:set putSuccess;

:log info "=== END: config-dhcp ==="
