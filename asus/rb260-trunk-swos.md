# RB260GS VLAN trunk and access ports (SwOS)

Configures one RB260GS as the access switch for the AX86U-as-router POC. SwOS only has a web UI; this is a click-through guide, not a script.

## Role in the POC topology

```
CRS106 sfp2 ── (fiber trunk, VID 10 + 50 tagged) ──> RB260GS SFP
                                                     RB260GS Port1 → laptop on VLAN 10
                                                     RB260GS Port2 → laptop on VLAN 50
```

The SFP port carries tagged frames for VID 10 and VID 50. Port1 and Port2 are untagged access ports: the switch tags incoming frames with the port's Default VLAN ID, and strips the tag on egress so the laptop sees plain Ethernet.

## SwOS port naming

By default SwOS labels the ports `SFP`, `Port1`, `Port2`, `Port3`, `Port4`, `Port5`. Renaming them in the Link tab is optional and makes the VLAN tab columns self-documenting. Suggested renames:

| Default | Suggested name |
|---------|----------------|
| SFP     | trunk          |
| Port1   | vlan10         |
| Port2   | vlan50         |
| Port3, Port4, Port5 | leave default |

The instructions below use the default names. Substitute the renamed labels if you applied them.

## Step 1: Link tab (optional rename)

Edit the Name field for each port you want to rename, then click **Apply All**.

## Step 2: VLANs tab (the VLAN membership table)

This tab has one row per VLAN, with a per-port dropdown showing four options. The options describe the per-VLAN egress action for each port:

| SwOS dropdown    | Meaning                                                      |
|------------------|--------------------------------------------------------------|
| add if missing   | egress always tagged (tag added if frame is untagged)        |
| always strip     | egress always untagged (tag stripped on the way out)         |
| not a member     | port is not part of this VLAN                                |
| leave as is      | pass the frame through unchanged (unused for this config)    |

Click **Append** at the bottom of the table to add a row, then set the dropdowns. Add two rows.

**Row 1: VLAN ID = 10**

| Column | Set to |
|--------|--------|
| SFP    | add if missing |
| Port1  | always strip   |
| Port2  | not a member   |
| Port3  | not a member   |
| Port4  | not a member   |
| Port5  | not a member   |

**Row 2: VLAN ID = 50**

| Column | Set to |
|--------|--------|
| SFP    | add if missing |
| Port1  | not a member   |
| Port2  | always strip   |
| Port3  | not a member   |
| Port4  | not a member   |
| Port5  | not a member   |

Click **Apply All**.

## Step 3: VLAN tab (per-port behaviour)

This tab has per-port columns and is split into an Ingress section (VLAN Mode, VLAN Receive, Default VLAN ID, Force VLAN ID) and an Egress section (VLAN Header).

The dropdown options on this tab are:

| Setting     | Options                                          |
|-------------|--------------------------------------------------|
| VLAN Mode   | disabled, optional, enabled, strict              |
| VLAN Receive| any, only tagged, only untagged                  |
| VLAN Header | leave as is, always strip, add if missing        |

Set the columns as follows. Port3 through Port5 stay at defaults (`optional` / `any` / `1` / unchecked / `leave as is`).

| Setting                  | SFP            | Port1           | Port2           |
|--------------------------|----------------|-----------------|-----------------|
| **VLAN Mode**            | strict         | strict          | strict          |
| **VLAN Receive**         | only tagged    | only untagged   | only untagged   |
| **Default VLAN ID**      | 1              | 10              | 50              |
| **Force VLAN ID**        | unchecked      | unchecked       | unchecked       |
| **VLAN Header** (Egress) | add if missing | always strip    | always strip    |

Click **Apply All**.

Notes on the settings:

- `strict` mode enforces VLAN membership; frames for VIDs the port is not a member of get dropped.
- `only tagged` on the SFP trunk drops untagged frames. A trunk should never see untagged.
- `only untagged` on Port1 and Port2 drops tagged frames from the laptop side. Laptops should not be tagging.
- `Default VLAN ID` is the PVID, the VID assigned to untagged ingress frames. Matches the access port's role.
- `Force VLAN ID` stays unchecked. We don't want to override existing tags on ingress; that pattern is for QinQ.
- The Egress `VLAN Header` setting is the per-port default behaviour, supplementing the per-VLAN dropdowns in the VLANs tab.

## Step 4: System tab (save)

SwOS keeps your changes in volatile RAM until you save them. Click **Save Configuration** so the config survives a reboot.

## Verification

After applying the CRS106 and ASUS-side configs, and wiring CRS106 sfp2 to RB260GS SFP via fiber:

- Plug laptop into Port1 (or `vlan10` if renamed). DHCP from the ASUS should land `192.168.10.x` with gateway `192.168.10.1`.
- Plug laptop into Port2 (or `vlan50` if renamed). DHCP should land `192.168.50.x` with gateway `192.168.50.1`. Speedtest from here measures the full ASUS to CRS to RB260GS chain.
- From the VLAN 50 laptop, `ping 192.168.50.1` (ASUS gateway) and `ping 192.168.50.2` (CRS management) should both work.
- From the VLAN 50 laptop, any attempt to reach a `192.168.10.x` host should fail. The ASUS enforces inter-VLAN isolation symmetrically.

## Notes

- SwOS settings are per-device. If you reuse a different RB260GS unit, repeat these steps on it.
- For a clean starting state, use **System** > **Reset Configuration** before step 1.
