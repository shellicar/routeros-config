# config/dhcp
# Configure DHCP pool, server, and network for bridge interface
# policy=read,write

:log info "=== START: config-dhcp ==="

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

$configureDHCP

:set configureDHCP;

:log info "=== END: config-dhcp ==="
