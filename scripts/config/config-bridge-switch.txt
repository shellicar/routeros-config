# config/bridge-switch
# Configure bridge mode with combo1 as bridge port
# policy=read,write

:log info "=== START: config-bridge-switch ==="

:global renameInterface do={
    :put "=== Configuring combo1 interface (rename to combo1-bridge) ==="
    /interface set combo1 name="combo1-bridge"
    :put "Renamed combo1 to combo1-bridge"
    :log info "Renamed combo1 to combo1-bridge"
    :put ""
}

:global unconfigureNAT do={
    :put "=== BEFORE: Checking NAT rules ==="
    /ip firewall nat print where chain="srcnat" and (out-interface="combo1-bridge" or out-interface="combo1-WAN") and action="masquerade"
    :put ""

    :put "=== Removing NAT masquerade rule ==="
    :local natCount [:len [/ip firewall nat find where chain="srcnat" and (out-interface="combo1-bridge" or out-interface="combo1-WAN") and action="masquerade"]]
    :if ($natCount > 0) do={
        /ip firewall nat remove [find where chain="srcnat" and (out-interface="combo1-bridge" or out-interface="combo1-WAN") and action="masquerade"]
        :put "Removed NAT masquerade rule"
        :log info "Removed NAT masquerade rule"
    } else={
        :put "No NAT masquerade rule found, skipping"
        :log debug "No NAT masquerade rule found, skipping"
    }
    :put ""

    :put "=== AFTER: Checking NAT rules ==="
    /ip firewall nat print where chain="srcnat" and (out-interface="combo1-bridge" or out-interface="combo1-WAN")
    :put ""
}

:global unconfigureWanIP do={
    :put "=== Removing IP address from combo1-bridge (expected: no IP on combo1-bridge) ==="
    :local comboIpCount [:len [/ip address find interface="combo1-bridge"]]
    :if ($comboIpCount > 0) do={
        /ip address remove [find interface="combo1-bridge"]
        :put "Removed IP address from combo1-bridge"
        :log info "Removed IP address from combo1-bridge"
    } else={
        :put "combo1-bridge has no IP address, skipping"
        :log debug "combo1-bridge has no IP address, skipping"
    }
    :put ""
}

:global configureBridgePort do={
    :put "=== Adding combo1-bridge to bridge (expected: combo1-bridge in bridge ports) ==="
    :if ([:len [/interface bridge port find interface="combo1-bridge"]] = 0) do={
        /interface bridge port add bridge="bridge" interface="combo1-bridge"
        :put "Added combo1-bridge to bridge"
        :log info "Added combo1-bridge to bridge"
    } else={
        :put "combo1-bridge already in bridge, skipping"
        :log debug "combo1-bridge already in bridge, skipping"
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

:set renameInterface;
:set unconfigureNAT;
:set unconfigureWanIP;
:set configureBridgePort;

:log info "=== END: config-bridge-switch ==="
