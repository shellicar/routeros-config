# RouterOS Configuration Scripts

Personal RouterOS configuration scripts for home network management.

## Overview

This repository contains RouterOS scripts to configure and diagnose a MikroTik router. Configuration scripts set up router modes (routing, bridging, NAT, DHCP). Check scripts display router settings and diagnostics.

## Quick Start

### Running Scripts

Run scripts on the router using forward slashes:

```routeros
/system script run config/firewall
/system script run check/nat
```

## Network Configuration

The `combo1` port is renamed to `combo1-WAN` for routing mode or `combo1-bridge` for switching mode. The `bridge` interface is used for the internal network.

The WAN interface uses `192.168.200.2/24` with gateway `192.168.200.1`. The bridge interface uses `192.168.88.1/24` as the gateway for the internal network. DHCP serves addresses from `192.168.88.100-192.168.88.199`.

## Hardware

These scripts are tested on CRS106, a MikroTik switch/router.

## Repository Structure

```text
routeros-config/
├── scripts/
│   ├── config/          # Configuration scripts
│   ├── check/           # Diagnostic scripts
│   └── README.md        # Format and syntax guidelines
└── README.md            # This file
```

For format and syntax guidelines, see [scripts/README.md](scripts/README.md).
