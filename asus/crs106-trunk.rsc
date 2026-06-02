# asus/crs106-trunk.rsc
# Configure CRS106 as a hardware-accelerated L2 VLAN trunk switch for the
# AX86U-as-router POC. Uses the QCA8511 switch chip's VLAN tables directly
# (not bridge vlan-filtering), so VLAN tagging happens in hardware at
# line-rate instead of in software through the CPU.
#
# policy=read,write
#
# Why switch-chip instead of bridge vlan-filtering: per the official
# RouterOS Bridging and Switching docs (Hardware Offloading section),
# CRS1xx/2xx series with QCA chips do NOT support hardware offload when
# bridge vlan-filtering is enabled. That puts every frame on the CPU,
# capping the device at ~300Mbps. The Basic VLAN Switching guide's
# CRS1xx/2xx pattern (ingress-vlan-translation + egress-vlan-tag +
# switch vlan table) keeps frames in the switch chip and reaches the
# spec'd ~5,922Mbps L2 throughput.
#
# Role in the POC topology:
#   ASUS ethN ── (RJ45 trunk, VID 10 + 50 tagged) ──> CRS106 combo1
#                                                     CRS106 sfp2 ── (fiber trunk) ──> RB260GS
#
# Port roles after this script:
#   combo1   trunk      tagged VID 10 + 50              ← ASUS
#   sfp1     EXCLUDED   hardware fault: continuous link flap
#   sfp2     trunk      tagged VID 10 + 50              → RB260GS
#   sfp3     access     untagged VID 10                 ← laptop (test VLAN 10)
#   sfp4     access     untagged VID 50                 ← laptop (test VLAN 50)
#   sfp5     RESCUE     OUT of bridge, static 192.168.99.1/24
#
# Management (normal): a /interface vlan on the bridge for VID 50 holds
# 192.168.50.2/24. The switch chip's egress-vlan-tag for VID 50 includes
# switch1-cpu, so VID 50 traffic egresses to the CPU side (the bridge),
# where the mgmt sub-interface decapsulates and terminates L3.
#
# Rescue (always-on): sfp5 stays outside the bridge with static
# 192.168.99.1/24. Plug a laptop with copper SFP into sfp5, set the
# laptop static at 192.168.99.2/24, reach the CRS at 192.168.99.1
# regardless of switch-chip state.
#
# Idempotent: re-running matches existing objects and updates in place.
# Also removes leftover bridge VLAN entries from any previous run that
# used bridge vlan-filtering (those are inert with vlan-filtering=no,
# but cleaning them avoids confusion in `print` output).

:log info "=== START: crs106-trunk ==="

# --- configuration ---------------------------------------------------------

:local bridgeName        "bridge"
:local cpuPort           "switch1-cpu"
:local trunkPorts        "combo1,sfp2"
:local accessVid10Ports  "sfp3"
:local accessVid50Ports  "sfp4,sfp1"
:local excludedPorts     ""
:local rescuePort        "sfp5"
:local rescueAddress     "192.168.99.1/24"
:local mgmtVlanId        50
:local mgmtVlanName      "mgmt"
:local mgmtAddress       "192.168.50.2/24"
:local mgmtGateway       "192.168.50.1"
:local cfgComment        "crs106-trunk"
:local rescueComment     "crs106-trunk-rescue"

# All switch-chip ports that participate in offloaded VLAN switching.
:local offloadedPorts ($trunkPorts . "," . $accessVid10Ports . "," . $accessVid50Ports)

# --- inline helpers --------------------------------------------------------

:global putOk do={
    { [/terminal style varname-local]; :put $1 }
    :log info $1
}

:global putWarn do={
    { [/terminal style syntax-meta]; :put $1 }
    :log warning $1
}

# --- bridge (vlan-filtering OFF — switch chip handles VLAN in HW) ---------

:put "=== Bridge (vlan-filtering=no; switch chip will tag/untag in hardware) ==="
:local bridgeId [/interface bridge find name=$bridgeName]
:if ([:len $bridgeId] = 0) do={
    /interface bridge add name=$bridgeName comment=$cfgComment vlan-filtering=no
    $putOk ("Created bridge " . $bridgeName)
} else={
    /interface bridge set $bridgeId comment=$cfgComment vlan-filtering=no
    $putOk ("Bridge " . $bridgeName . " exists; comment + vlan-filtering reset")
}
:put ""

# --- clean up old bridge VLAN entries from prior vlan-filtering config ----

:put "=== Removing old bridge VLAN entries (from any prior bridge vlan-filtering run) ==="
:foreach old in=[/interface bridge vlan find comment=$cfgComment] do={
    /interface bridge vlan remove $old
    $putOk "Removed old bridge VLAN entry"
}
:put ""

# --- rescue port (FIRST — always reachable if anything later fails) -------

:put "=== Rescue port: $rescuePort (out of bridge, static $rescueAddress) ==="

:local rescueBridgePort [/interface bridge port find interface=$rescuePort]
:if ([:len $rescueBridgePort] > 0) do={
    /interface bridge port remove $rescueBridgePort
    $putOk ("Removed " . $rescuePort . " from bridge")
}

:local rescueIpId [/ip address find interface=$rescuePort]
:if ([:len $rescueIpId] = 0) do={
    /ip address add address=$rescueAddress interface=$rescuePort comment=$rescueComment
    $putOk ("Assigned " . $rescueAddress . " to " . $rescuePort)
} else={
    /ip address set $rescueIpId address=$rescueAddress interface=$rescuePort comment=$rescueComment
    $putOk ("Updated " . $rescuePort . " address to " . $rescueAddress)
}
/interface enable $rescuePort
:put ""

# --- excluded ports (kept out of the bridge) ------------------------------

:if ([:len $excludedPorts] > 0) do={
    :put "=== Excluded ports (kept out of the bridge) ==="
    :foreach p in=[:toarray $excludedPorts] do={
        :if ([:len $p] > 0) do={
            :local portId [/interface bridge port find interface=$p]
            :if ([:len $portId] > 0) do={
                /interface bridge port remove $portId
                $putOk ("Removed " . $p . " from bridge (excluded)")
            } else={
                $putOk ($p . " already out of bridge")
            }
        }
    }
    :put ""
}

# --- bridge ports (plain members — no frame-types/pvid; chip does the work) -

:put "=== Bridge ports (plain L2 members; switch chip controls VLAN) ==="
:foreach p in=[:toarray $offloadedPorts] do={
    :if ([:len $p] > 0) do={
        :local portId [/interface bridge port find interface=$p]
        :if ([:len $portId] = 0) do={
            /interface bridge port add bridge=$bridgeName interface=$p comment=$cfgComment
            $putOk ("Added bridge port " . $p)
        } else={
            /interface bridge port set $portId bridge=$bridgeName comment=$cfgComment \
                frame-types=admit-all pvid=1
            $putOk ("Updated bridge port " . $p . " (reset to plain L2 member)")
        }
    }
}
:put ""

# --- switch chip: ingress VLAN translation (PVID for access ports) --------

# customer-vid=0 matches untagged ingress; new-customer-vid sets the VID
# the switch chip stamps onto those frames. This is the hardware equivalent
# of bridge port pvid.
:put "=== Switch chip ingress-vlan-translation (untagged → VID per access port) ==="

:foreach p in=[:toarray $accessVid10Ports] do={
    :if ([:len $p] > 0) do={
        :local tx [/interface ethernet switch ingress-vlan-translation find ports=$p customer-vid=0]
        :if ([:len $tx] = 0) do={
            /interface ethernet switch ingress-vlan-translation \
                add ports=$p customer-vid=0 new-customer-vid=10 comment=$cfgComment
            $putOk ("Added ingress xlate " . $p . " untagged → VID 10")
        } else={
            /interface ethernet switch ingress-vlan-translation \
                set $tx ports=$p customer-vid=0 new-customer-vid=10 comment=$cfgComment
            $putOk ("Updated ingress xlate " . $p . " untagged → VID 10")
        }
    }
}

:foreach p in=[:toarray $accessVid50Ports] do={
    :if ([:len $p] > 0) do={
        :local tx [/interface ethernet switch ingress-vlan-translation find ports=$p customer-vid=0]
        :if ([:len $tx] = 0) do={
            /interface ethernet switch ingress-vlan-translation \
                add ports=$p customer-vid=0 new-customer-vid=50 comment=$cfgComment
            $putOk ("Added ingress xlate " . $p . " untagged → VID 50")
        } else={
            /interface ethernet switch ingress-vlan-translation \
                set $tx ports=$p customer-vid=0 new-customer-vid=50 comment=$cfgComment
            $putOk ("Updated ingress xlate " . $p . " untagged → VID 50")
        }
    }
}
:put ""

# --- switch chip: egress VLAN tag (trunks get the tag; CPU sees mgmt) -----

:put "=== Switch chip egress-vlan-tag (which ports egress tagged for each VID) ==="

# VID 10: tagged on trunk ports only (no CPU — we don't terminate VID 10 on the CRS).
:local egress10 [/interface ethernet switch egress-vlan-tag find vlan-id=10]
:if ([:len $egress10] = 0) do={
    /interface ethernet switch egress-vlan-tag \
        add tagged-ports=$trunkPorts vlan-id=10 comment=$cfgComment
    $putOk "Added egress-vlan-tag VID=10 on trunks"
} else={
    /interface ethernet switch egress-vlan-tag \
        set $egress10 tagged-ports=$trunkPorts vlan-id=10 comment=$cfgComment
    $putOk "Updated egress-vlan-tag VID=10 on trunks"
}

# VID 50: tagged on trunk ports AND switch-cpu (so mgmt sub-interface gets VID 50 traffic).
:local egress50Ports ($trunkPorts . "," . $cpuPort)
:local egress50 [/interface ethernet switch egress-vlan-tag find vlan-id=50]
:if ([:len $egress50] = 0) do={
    /interface ethernet switch egress-vlan-tag \
        add tagged-ports=$egress50Ports vlan-id=50 comment=$cfgComment
    $putOk "Added egress-vlan-tag VID=50 on trunks + switch-cpu"
} else={
    /interface ethernet switch egress-vlan-tag \
        set $egress50 tagged-ports=$egress50Ports vlan-id=50 comment=$cfgComment
    $putOk "Updated egress-vlan-tag VID=50 on trunks + switch-cpu"
}
:put ""

# --- switch chip: VLAN membership table -----------------------------------

:put "=== Switch chip VLAN membership table ==="

# VID 10: trunks + access VID 10 ports.
:local vlan10Members ($trunkPorts . "," . $accessVid10Ports)
:local vlan10Id [/interface ethernet switch vlan find vlan-id=10]
:if ([:len $vlan10Id] = 0) do={
    /interface ethernet switch vlan \
        add ports=$vlan10Members vlan-id=10 comment=$cfgComment
    $putOk ("Added switch VLAN 10 members: " . $vlan10Members)
} else={
    /interface ethernet switch vlan \
        set $vlan10Id ports=$vlan10Members vlan-id=10 comment=$cfgComment
    $putOk ("Updated switch VLAN 10 members: " . $vlan10Members)
}

# VID 50: trunks + access VID 50 ports + switch-cpu (for L3 termination).
:local vlan50Members ($trunkPorts . "," . $accessVid50Ports . "," . $cpuPort)
:local vlan50Id [/interface ethernet switch vlan find vlan-id=50]
:if ([:len $vlan50Id] = 0) do={
    /interface ethernet switch vlan \
        add ports=$vlan50Members vlan-id=50 comment=$cfgComment
    $putOk ("Added switch VLAN 50 members: " . $vlan50Members)
} else={
    /interface ethernet switch vlan \
        set $vlan50Id ports=$vlan50Members vlan-id=50 comment=$cfgComment
    $putOk ("Updated switch VLAN 50 members: " . $vlan50Members)
}
:put ""

# --- management VLAN sub-interface on the bridge --------------------------

:put "=== Management VLAN sub-interface (VID $mgmtVlanId on bridge) ==="
:local vlanIfId [/interface vlan find name=$mgmtVlanName]
:if ([:len $vlanIfId] = 0) do={
    /interface vlan add interface=$bridgeName vlan-id=$mgmtVlanId \
        name=$mgmtVlanName comment=$cfgComment
    $putOk ("Created VLAN interface " . $mgmtVlanName . " (VID " . $mgmtVlanId . ")")
} else={
    /interface vlan set $vlanIfId interface=$bridgeName vlan-id=$mgmtVlanId comment=$cfgComment
    $putOk ("Updated VLAN interface " . $mgmtVlanName)
}

:put "=== Management IP address ==="
:local ipId [/ip address find interface=$mgmtVlanName]
:if ([:len $ipId] = 0) do={
    /ip address add address=$mgmtAddress interface=$mgmtVlanName comment=$cfgComment
    $putOk ("Assigned " . $mgmtAddress . " to " . $mgmtVlanName)
} else={
    /ip address set $ipId address=$mgmtAddress interface=$mgmtVlanName comment=$cfgComment
    $putOk ("Updated " . $mgmtVlanName . " address to " . $mgmtAddress)
}

:put "=== Default route via ASUS ==="
:local routeId [/ip route find dst-address="0.0.0.0/0" gateway=$mgmtGateway]
:if ([:len $routeId] = 0) do={
    /ip route add dst-address="0.0.0.0/0" gateway=$mgmtGateway comment=$cfgComment
    $putOk ("Added default route -> " . $mgmtGateway)
} else={
    /ip route set $routeId gateway=$mgmtGateway comment=$cfgComment
    $putOk ("Updated default route gateway -> " . $mgmtGateway)
}
:put ""

# --- switch chip: drop invalid VLAN frames on offloaded ports -------------

:put "=== Switch chip: drop-if-invalid on offloaded ports ==="
/interface ethernet switch set drop-if-invalid-or-src-port-not-member-of-vlan-on-ports=$offloadedPorts
$putOk ("Set drop-if-invalid on: " . $offloadedPorts)
:put ""

# --- summary --------------------------------------------------------------

:put "=== Summary ==="
:put "Bridge:"
/interface bridge print where name=$bridgeName
:put ""
:put "Bridge ports:"
/interface bridge port print where bridge=$bridgeName
:put ""
:put "Switch VLAN table:"
/interface ethernet switch vlan print
:put ""
:put "Switch ingress-vlan-translation:"
/interface ethernet switch ingress-vlan-translation print
:put ""
:put "Switch egress-vlan-tag:"
/interface ethernet switch egress-vlan-tag print
:put ""
:put "VLAN sub-interfaces:"
/interface vlan print
:put ""
:put "IP addresses:"
/ip address print
:put ""

$putWarn "Reachable via: 192.168.99.1 (sfp5 rescue, always works)"
$putWarn "          OR: 192.168.50.2 (mgmt, via VID 50 access port or trunk)"
$putWarn "Switch chip now handles VLAN in hardware — expect line-rate throughput."

:set putOk;
:set putWarn;

:log info "=== END: crs106-trunk ==="
