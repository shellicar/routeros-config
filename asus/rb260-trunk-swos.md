# RB260GS — VLAN trunk + access ports (SwOS)

Configures one RB260GS as the access switch for the AX86U-as-router POC.
SwOS only has a web UI; this is a click-through guide, not a script.

## Role in the POC topology

```
CRS106 sfp2 ── (fiber trunk, VID 10 + 50 tagged) ──> RB260GS sfp1
                                                     RB260GS eth1 → laptop on VLAN 10
                                                     RB260GS eth2 → laptop on VLAN 50
```

`sfp1` carries tagged frames for VID 10 and VID 50. `eth1` and `eth2` are
untagged access ports — the switch tags incoming frames with the port's PVID
and strips the tag on egress so the laptop sees plain Ethernet.

## Desired port configuration

| Port  | Role         | VLAN Mode | VLAN Receive       | Default VLAN ID (PVID) | Member of VIDs        |
|-------|--------------|-----------|--------------------|------------------------|-----------------------|
| sfp1  | Trunk        | strict    | only tagged        | 1 (unused)             | 10 (tagged), 50 (tagged) |
| eth1  | Access VID 10| strict    | only untagged      | 10                     | 10 (untagged)         |
| eth2  | Access VID 50| strict    | only untagged      | 50                     | 50 (untagged)         |
| eth3  | (unused)     | leave default                                                          |
| eth4  | (unused)     | leave default                                                          |
| eth5  | (unused)     | leave default                                                          |

## SwOS click-through

Open the web UI in a browser (default credentials, default IP — adjust if
you've changed them).

### 1. VLANs tab — declare the VLAN membership table

For each VID, declare which ports are members and whether tagged or untagged.

Add two rows:

| VLAN ID | Members (tagged) | Members (untagged) |
|---------|------------------|--------------------|
| 10      | sfp1             | eth1               |
| 50      | sfp1             | eth2               |

Apply.

### 2. VLAN tab — per-port settings

| Port  | VLAN Mode | VLAN Receive       | Default VLAN ID |
|-------|-----------|--------------------|-----------------|
| sfp1  | strict    | only tagged        | 1               |
| eth1  | strict    | only untagged      | 10              |
| eth2  | strict    | only untagged      | 50              |

`strict` mode enforces the receive rule (frames violating it are dropped).
`only tagged` on sfp1 means untagged frames arriving there are dropped — a
true trunk. `only untagged` on eth1/eth2 means tagged frames from the laptop
side are dropped (laptops shouldn't be tagging).

Apply.

### 3. System tab — save the running config

SwOS holds changes in volatile state until you save them. Click **Save** so
the config survives a reboot.

## Verification

After applying CRS106 and ASUS-side configs and wiring the cables:

- Plug laptop into **eth1** — DHCP from ASUS, expect `192.168.10.x`, gateway `.1`.
- Plug laptop into **eth2** — DHCP from ASUS, expect `192.168.50.x`, gateway `.1`.
- From laptop on eth2, ping `192.168.50.1` (ASUS) — should work.
- From laptop on eth2, ping `192.168.50.2` (CRS106 management) — should work.
- From laptop on eth2, try to reach `192.168.10.x` — should fail (inter-VLAN isolation enforced by ASUS).

## Notes

- `sfp1` is the fiber upstream link. If you're using a different RB260GS port
  for upstream during testing (e.g. an RJ45 trunk from the ASUS direct), swap
  `sfp1` for the actual port in steps 1 and 2.
- SwOS settings are per-device. If you reuse a different RB260GS unit, repeat
  these steps on it.
- For a clean starting state, **System → Reset Configuration** before step 1.
