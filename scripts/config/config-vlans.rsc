# config/vlans
# Configure vlans, bridge, and dhcp for vlan setup
# policy=read,write

:log info "=== START: config-vlans ==="

:global putSuccess do={
  { [/terminal style varname-local]; :put $1 }
  :log info $1
}

:global putWarning do={
  { [/terminal style syntax-meta]; :put $1 }
  :log warning $1
}

{

# Bridge name for VLAN testing (isolated from main bridge)
:local bridgeName "bridge-vlan"

# VLAN ID variables
:local vlanPrimaryId 10
:local vlanSecondaryId 20
:local vlanIotId 30
:local vlanManagementId 99

# VLAN comment variables
:local vlanPrimaryComment "vlan-primary"
:local vlanSecondaryComment "vlan-secondary"
:local vlanIotComment "vlan-iot"
:local vlanManagementComment "vlan-management"

# VLAN subnet prefix variables (without last octet)
:local vlanPrimarySubnetPrefix "10.0.10"
:local vlanSecondarySubnetPrefix "10.0.20"
:local vlanIotSubnetPrefix "10.0.30"
:local vlanManagementSubnetPrefix "10.0.99"

:local configureBridgeVLAN do={
    # Parameter: bridgeName = name of the bridge interface (passed as bridgeName=$bridgeName)
    
    :global putSuccess
    
    :put "=== Configuring bridge for vlan filtering ==="
    :put "Note: vlan-filtering will be enabled at the end after all vlan config"
    :put "Note: CRS1xx/2xx will auto-create reserved vlans (4091, 4090, etc.) for hardware offloading"
    :put ""
    
    # Ensure bridge exists and configure frame-types
    :local bridgeId [/interface bridge find name="$bridgeName"]
    :if ($bridgeId = "") do={
        /interface bridge add name="$bridgeName" comment="VLAN test bridge"
        $putSuccess ("Created bridge interface " . $bridgeName) info
    } else={
        /interface bridge set $bridgeId comment="VLAN test bridge"
        $putSuccess ("Updated bridge " . $bridgeName) info
    }
    
    # Enable hardware offloading for CRS1xx/2xx series (if supported)
    # This allows VLAN switching to use the switch chip instead of CPU
    /interface bridge set "$bridgeName" frame-types=admit-only-vlan-tagged
    $putSuccess ("Bridge " . $bridgeName . " configured for vlan filtering") info
    :put ""
    
    :put ("=== Bridge configuration (" . $bridgeName . ") ===")
    /interface bridge print where name="$bridgeName"
    :put ""
}

:local configureVLAN do={
    # Parameters (named):
    # bridgeName = name of the bridge interface
    # vlanId = vlan id (e.g., 10)
    # comment = vlan comment/name (e.g., "primary")
    # subnetPrefix = subnet prefix without last octet (e.g., "192.168.50")
    
    :global putSuccess
    
    :local gateway ($subnetPrefix . ".1")
    :local subnet ($subnetPrefix . ".0/24")
    :local gatewayIp ($gateway . "/24")
    :local dhcpRange ($subnetPrefix . ".100-" . $subnetPrefix . ".199")
    
    :put ("=== Configuring vlan: " . $comment . " (vlan " . $vlanId . ") ===")
    
    :local vlanInterfaceId [/interface vlan find comment="$comment"]
    :if ($vlanInterfaceId = "") do={
        /interface vlan add interface="$bridgeName" vlan-id=$vlanId name="$comment" comment="$comment"
        $putSuccess ("Created vlan interface " . $comment . " (vlan " . $vlanId . ")") info
    } else={
        /interface vlan set $vlanInterfaceId vlan-id=$vlanId name="$comment" comment="$comment"
        $putSuccess ("Updated vlan interface " . $comment) info
    }
    
    :local bridgeVlanId [/interface bridge vlan find bridge="$bridgeName" comment="$comment"]
    :if ($bridgeVlanId = "") do={
        /interface bridge vlan add bridge="$bridgeName" tagged="$bridgeName" vlan-ids=($vlanId) comment="$comment"
        $putSuccess ("Added bridge vlan entry for " . $comment) info
    } else={
        /interface bridge vlan set $bridgeVlanId vlan-ids=($vlanId)
        $putSuccess ("Updated bridge vlan entry for " . $comment) info
    }
    
    :local vlanInterfaceName [/interface vlan get $vlanInterfaceId name]
    :local ipAddressId [/ip address find interface="$vlanInterfaceName" comment="$comment"]
    :if ($ipAddressId = "") do={
        /ip address add address="$gatewayIp" interface="$vlanInterfaceName" comment="$comment"
        $putSuccess ("Added IP " . $gatewayIp . " to " . $vlanInterfaceName) info
    } else={
        /ip address set $ipAddressId address="$gatewayIp" interface="$vlanInterfaceName" comment="$comment"
        $putSuccess ("Updated IP on " . $vlanInterfaceName . " to " . $gatewayIp) info
    }
    
    :local poolName ("dhcp-pool-" . $comment)
    :local poolId [/ip pool find name="$poolName"]
    :if ($poolId = "") do={
        /ip pool add name="$poolName" ranges="$dhcpRange" comment="$comment"
        $putSuccess ("Added dhcp pool " . $poolName) info
    } else={
        /ip pool set $poolId ranges="$dhcpRange" comment="$comment"
        $putSuccess ("Updated dhcp pool " . $poolName) info
    }
    
    :local dhcpServerId [/ip dhcp-server find interface="$vlanInterfaceName" comment="$comment"]
    :if ($dhcpServerId = "") do={
        /ip dhcp-server add interface="$vlanInterfaceName" address-pool="$poolName" name=("dhcp-" . $comment) comment="$comment"
        $putSuccess ("Added dhcp server dhcp-" . $comment) info
    } else={
        /ip dhcp-server set $dhcpServerId interface="$vlanInterfaceName" address-pool="$poolName" comment="$comment"
        $putSuccess ("Updated dhcp server dhcp-" . $comment) info
    }
    
    :local dhcpNetworkId [/ip dhcp-server network find address="$subnet" comment="$comment"]
    :if ($dhcpNetworkId = "") do={
        /ip dhcp-server network add address="$subnet" gateway="$gateway" comment="$comment"
        $putSuccess ("Added dhcp network " . $subnet) info
    } else={
        /ip dhcp-server network set $dhcpNetworkId gateway="$gateway" comment="$comment"
        $putSuccess ("Updated dhcp network " . $subnet) info
    }
    
    :put ""
}

:local configureBridgePorts do={
    # Parameter: bridgeName = name of the bridge interface (passed as bridgeName=$bridgeName)
    
    :put "=== Configuring bridge ports ==="
    :put "TODO: Add physical ports to bridge"
    :put ("Example: /interface bridge port add bridge=" . $bridgeName . " interface=sfp1")
    :put ("Example: /interface bridge port add bridge=" . $bridgeName . " interface=sfp2 pvid=10 frame-types=admit-only-untagged-and-priority-tagged")
    :put ("Example: /interface bridge port add bridge=" . $bridgeName . " interface=sfp3 frame-types=admit-only-vlan-tagged (for trunk)")
    :put ""
    :put ("Current bridge ports for " . $bridgeName . ":")
    /interface bridge port print where bridge="$bridgeName"
    :put ""
}

:local configureDNS do={
    :global putSuccess
    
    :put "=== Configuring dns remote requests ==="
    /ip dns set allow-remote-requests=yes
    $putSuccess "Enabled dns remote requests (vlans can use CRS as dns server)" info
    :put ""
    /ip dns print
    :put ""
}

:local enableVLANFiltering do={
    # Parameter: bridgeName = name of the bridge interface (passed as bridgeName=$bridgeName)
    
    :global putSuccess
    :global putWarning
    
    :put ("=== Enabling vlan filtering on bridge " . $bridgeName . " (MUST be last step) ===")
    /interface bridge set "$bridgeName" vlan-filtering=yes
    $putSuccess ("vlan filtering enabled on bridge " . $bridgeName) info
    :put ""
    $putWarning "WARNING: Ensure all vlan configuration is complete before enabling!"
    $putWarning "If you lose access, you may need to access via console or reset"
    :put ""
}

$configureBridgeVLAN bridgeName=$bridgeName
$configureBridgePorts bridgeName=$bridgeName

# Configure each VLAN completely (interface, bridge vlan, IP, DHCP)
$configureVLAN bridgeName=$bridgeName vlanId=$vlanPrimaryId comment=$vlanPrimaryComment subnetPrefix=$vlanPrimarySubnetPrefix
$configureVLAN bridgeName=$bridgeName vlanId=$vlanSecondaryId comment=$vlanSecondaryComment subnetPrefix=$vlanSecondarySubnetPrefix
$configureVLAN bridgeName=$bridgeName vlanId=$vlanIotId comment=$vlanIotComment subnetPrefix=$vlanIotSubnetPrefix
$configureVLAN bridgeName=$bridgeName vlanId=$vlanManagementId comment=$vlanManagementComment subnetPrefix=$vlanManagementSubnetPrefix

:put "=== vlan configuration summary ==="
/interface vlan print
:put ""
/interface bridge vlan print
:put ""
/ip address print where interface="$vlanPrimaryComment" or interface="$vlanSecondaryComment" or interface="$vlanIotComment" or interface="$vlanManagementComment"
:put ""
/ip pool print where comment="$vlanPrimaryComment" or comment="$vlanSecondaryComment" or comment="$vlanIotComment" or comment="$vlanManagementComment"
:put ""
/ip dhcp-server print where comment="$vlanPrimaryComment" or comment="$vlanSecondaryComment" or comment="$vlanIotComment" or comment="$vlanManagementComment"
:put ""
/ip dhcp-server network print where comment="$vlanPrimaryComment" or comment="$vlanSecondaryComment" or comment="$vlanIotComment" or comment="$vlanManagementComment"
:put ""

$configureDNS
$enableVLANFiltering bridgeName=$bridgeName

}

:set putSuccess;
:set putWarning;

:log info "=== END: config-vlans ==="
