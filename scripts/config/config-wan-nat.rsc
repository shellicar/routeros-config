# config/wan-nat
# Configure router mode with WAN interface and NAT masquerading
# policy=read,write

:log info "=== START: config-wan-nat ==="

:global renameInterface do={
    :put "=== Configuring combo1 interface (rename to combo1-WAN) ==="
    /interface set combo1 name="combo1-WAN"
    :put "Renamed combo1 to combo1-WAN"
    :log info "Renamed combo1 to combo1-WAN"
    :put ""
}

:global removeFromBridge do={
    :put "=== Removing combo1-WAN from bridge (expected: combo1-WAN NOT in bridge) ==="
    :local bridgePortId [/interface bridge port find interface="combo1-WAN"]
    :if ([:len $bridgePortId] > 0) do={
        /interface bridge port remove $bridgePortId
        :put "Removed combo1-WAN from bridge"
        :log info "Removed combo1-WAN from bridge"
    } else={
        :put "combo1-WAN is not in bridge, skipping"
        :log debug "combo1-WAN is not in bridge, skipping"
    }
    :put ""

    :put "=== Verifying bridge ports (expected: combo1-WAN NOT listed) ==="
    /interface bridge port print where interface="combo1-WAN"
    :put ""
}

:global configureDHCP do={
    :put "=== Configuring DHCP pool (expected: dhcp-pool-bridge range 192.168.88.100-192.168.88.199) ==="
    :local poolId [/ip pool find name="dhcp-pool-bridge"]
    :if ([:len $poolId] = 0) do={
        /ip pool add name="dhcp-pool-bridge" ranges="192.168.88.100-192.168.88.199"
        :put "Added DHCP pool dhcp-pool-bridge"
        :log info "Added DHCP pool dhcp-pool-bridge"
    } else={
        /ip pool set $poolId ranges="192.168.88.100-192.168.88.199"
        :put "Updated DHCP pool dhcp-pool-bridge range"
        :log info "Updated DHCP pool dhcp-pool-bridge range"
    }
    /ip pool print where name="dhcp-pool-bridge"
    :put ""

    :put "=== Configuring DHCP server (expected: dhcp-bridge on bridge interface) ==="
    :if ([:len [/ip dhcp-server find interface="bridge"]] = 0) do={
        /ip dhcp-server add interface="bridge" address-pool="dhcp-pool-bridge" name="dhcp-bridge"
        :put "Added DHCP server dhcp-bridge"
        :log info "Added DHCP server dhcp-bridge"
    } else={
        :put "DHCP server on bridge already exists, skipping"
        :log debug "DHCP server on bridge already exists, skipping"
    }
    /ip dhcp-server print where interface="bridge"
    :put ""

    :put "=== Configuring DHCP network (expected: 192.168.88.0/24 gateway 192.168.88.1) ==="
    :if ([:len [/ip dhcp-server network find address="192.168.88.0/24"]] = 0) do={
        /ip dhcp-server network add address="192.168.88.0/24" gateway="192.168.88.1"
        :put "Added DHCP network 192.168.88.0/24"
        :log info "Added DHCP network 192.168.88.0/24"
    } else={
        :put "DHCP network 192.168.88.0/24 already exists, skipping"
        :log debug "DHCP network 192.168.88.0/24 already exists, skipping"
    }
    /ip dhcp-server network print where address="192.168.88.0/24"
    :put ""
}

:global configureWanIP do={
    :put "=== Configuring IP address on combo1-WAN (expected: 192.168.200.2/24) ==="
    :local wanIpId [/ip address find interface="combo1-WAN"]
    :if ([:len $wanIpId] = 0) do={
        /ip address add address="192.168.200.2/24" interface="combo1-WAN"
        :put "Added IP address 192.168.200.2/24 to combo1-WAN"
        :log info "Added IP address 192.168.200.2/24 to combo1-WAN"
    } else={
        /ip address set $wanIpId address="192.168.200.2/24"
        :put "Updated IP address on combo1-WAN to 192.168.200.2/24"
        :log info "Updated IP address on combo1-WAN to 192.168.200.2/24"
    }
    /ip address print where interface="combo1-WAN"
    :put ""

    :put "=== Configuring IP address on bridge (expected: 192.168.88.1/24) ==="
    :local bridgeIpId [/ip address find interface="bridge"]
    :if ([:len $bridgeIpId] = 0) do={
        /ip address add address="192.168.88.1/24" interface="bridge"
        :put "Added IP address 192.168.88.1/24 to bridge"
        :log info "Added IP address 192.168.88.1/24 to bridge"
    } else={
        /ip address set $bridgeIpId address="192.168.88.1/24"
        :put "Updated IP address on bridge to 192.168.88.1/24"
        :log info "Updated IP address on bridge to 192.168.88.1/24"
    }
    /ip address print where interface="bridge"
    :put ""
}

:global configureWanRoute do={
    :put "=== Configuring default route (expected: 0.0.0.0/0 gateway 192.168.200.1) ==="
    :local defaultRouteId [/ip route find dst-address="0.0.0.0/0"]
    :if ([:len $defaultRouteId] = 0) do={
        /ip route add dst-address="0.0.0.0/0" gateway="192.168.200.1"
        :put "Added default route 0.0.0.0/0 -> 192.168.200.1"
        :log info "Added default route 0.0.0.0/0 -> 192.168.200.1"
    } else={
        /ip route set $defaultRouteId gateway="192.168.200.1"
        :put "Updated default route gateway to 192.168.200.1"
        :log info "Updated default route gateway to 192.168.200.1"
    }
    /ip route print where dst-address="0.0.0.0/0"
    :put ""
}

:global configureNAT do={
    :put "=== BEFORE: Checking NAT rules ==="
    /ip firewall nat print where chain="srcnat" and out-interface="combo1-WAN" and action="masquerade"

    :if ([:len [/ip firewall nat find where chain="srcnat" and out-interface="combo1-WAN" and action="masquerade"]] = 0) do={
        /ip firewall nat add chain="srcnat" out-interface="combo1-WAN" action="masquerade"
        :put "Added NAT masquerade rule for combo1-WAN"
        :log info "Added NAT masquerade rule for combo1-WAN"
    } else={
        :put "NAT masquerade rule already exists, skipping"
        :log debug "NAT masquerade rule already exists, skipping"
    }
    :put ""

    :put "=== AFTER: Checking NAT rules ==="
    /ip firewall nat print where chain="srcnat" and out-interface="combo1-WAN" and action="masquerade"
    :put ""
}

$renameInterface
$removeFromBridge
$configureDHCP
$configureWanIP
$configureWanRoute
$configureNAT

:set renameInterface;
:set removeFromBridge;
:set configureDHCP;
:set configureWanIP;
:set configureWanRoute;
:set configureNAT;

:log info "=== END: config-wan-nat ==="
