# Home Network Configuration

Configuration for my home network, spanning RouterOS (MikroTik), Asuswrt-Merlin (ASUS), and SwOS (MikroTik). The repository started as RouterOS scripts for the CRS106 acting as L3 router. Those scripts now sit under `scripts/` as historical reference. Current focus is the proof-of-concept under `asus/` that puts an ASUS RT-AX86U in the router role with the MikroTiks reduced to L2 VLAN trunks.

## Repository structure

```
.
├── asus/        ASUS AX86U + MikroTik switch configs for the AX86U-as-router POC
├── scripts/     Earlier RouterOS scripts for CRS106 as L3 router (historical)
├── reference/   MikroTik documentation PDFs used during the POC
└── README.md
```

For RouterOS script conventions used under `scripts/`, see `scripts/README.md`.

## POC: AX86U as router, MikroTiks as VLAN trunks

```
NBN modem
   │
   ▼
ASUS RT-AX86U  (router: NAT, DHCP, firewall, inter-VLAN policy)
   │ trunk (RJ45, VID 10 + 50 tagged)
   ▼
CRS106         (L2 trunk via QCA switch chip)
   │ trunk (fiber, VID 10 + 50 tagged)
   ▼
RB260GS        (access switch, SwOS)
   │
   ▼ untagged access ports for laptop testing
```

VLANs:

- VLAN 10, subnet `192.168.10.0/24`, gateway `192.168.10.1` on the ASUS (isolated network)
- VLAN 50, subnet `192.168.50.0/24`, gateway `192.168.50.1` on the ASUS (main wired network)

Inter-VLAN forwarding is symmetrically denied at the ASUS. Both VLANs NAT out the WAN. DHCP is served by the ASUS for both subnets.

### Outcomes

The ASUS routes at line rate. A laptop on VLAN 50, plugged into the RB260GS at the end of the chain, reaches the ISP cap (500Mbps) on Ookla speedtests through NAT. VLAN isolation works as intended, matching the production intent that VLAN 10 carry separate downstream subnets (such as the TP-Link's) which must not reach VLAN 50. A laptop on VLAN 10 cannot initiate connections to VLAN 50; only ESTABLISHED returns traverse. The CRS106 in the middle of the chain operates with hardware VLAN offload via the QCA switch chip's own VLAN tables, not bridge vlan-filtering. The RB260GS provides untagged access ports via SwOS for the laptop-side test points.

### Critical finding: bridge vlan-filtering on CRS1xx/2xx is software only

The CRS1xx/2xx series (the CRS106's QCA8511 chip falls in this class) does not support hardware offload when bridge vlan-filtering is enabled. This is documented in the official RouterOS Bridging and Switching guide, in the Hardware Offloading section: only Marvell Prestera and a handful of newer chips support combined hardware offload with bridge vlan-filtering. With vlan-filtering=yes on a CRS106, every frame traverses the CPU and the device caps at around 300Mbps in practice, with CPU pegged at 90% or higher under load.

The working pattern for CRS1xx/2xx is the older switch-chip configuration, exposed as `/interface ethernet switch ingress-vlan-translation`, `/interface ethernet switch egress-vlan-tag`, and `/interface ethernet switch vlan`, with the bridge left as a passthrough (`vlan-filtering=no`). This is documented in the Basic VLAN switching guide under the CRS1xx/2xx section. Both PDFs are in `reference/`.

The bridge-based approach is still useful as the canonical pattern for newer MikroTik hardware (CRS3xx, CRS5xx, Marvell Prestera devices), where bridge vlan-filtering is hardware-accelerated. For CRS106 and similar older chips, the switch-chip pattern is the only way to reach line rate while still doing VLAN trunking.

## Next steps to production

The POC proved the topology and throughput. Moving from POC to daily use requires several pieces of work.

1. Update the home network diagrams (in the separate `network-diagrams` repository) to reflect the new desired state with the AX86U as router and the CRS106 demoted to a pure L2 trunk.

2. Add a dedicated management VLAN, likely VLAN 99. Management currently sits on VLAN 50 alongside main wired traffic, which is convenient for the POC but conflates roles in a production setup.

3. Update firewall rules so each device's management interface (the ASUS router, the CRS106, the RB260GS) is reachable only from the management VLAN. The current POC rejects all management traffic from the data VLANs, which is too restrictive for daily use without a dedicated management path in place.

4. WiFi planning is a future concern. The TP-Link's role as an isolated subnet matches the design intent for VLAN 10 and does not need to change. Hosting additional SSIDs on the AX86U's own radios is a later decision.

## Reference

The `reference/` directory holds the two MikroTik documentation PDFs that informed the CRS106 switch-chip approach:

- `bridging-and-switching.pdf`, the bridge feature reference. The Hardware Offloading section exposes the vlan-filtering limitation on older chips.
- `basic-vlan-switching.pdf`, the per-chip configuration patterns. The CRS1xx/2xx section gives the working `switch ingress-vlan-translation` / `egress-vlan-tag` / `vlan` pattern that the `asus/crs106-trunk.rsc` script implements.
