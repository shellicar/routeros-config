# RouterOS Scripts - Format and Syntax Guidelines

Format and syntax standards for RouterOS scripts.

## Format Guidelines

### Script Header

Scripts should start with a header:

```routeros
# [script-name]
# [Description of what the script does]
# Permissions: [permissions required]
```

**Examples:**

```routeros
# config/firewall
# Configure firewall rules for routing
# Permissions: read, write
```

```routeros
# check/nat
# Display NAT masquerade rule configuration and connection tracking
# Permissions: read
```

**Categories:**

- `config/` - Configuration scripts (require read, write permissions)
- `check/` - Diagnostic scripts (require read only)

### Script Structure

1. **Header** (name, description, permissions)
2. **Logging start:** `:log info "=== START: script-name ==="`
3. **Functions:** Define all `:global` functions first
4. **Execution:** Call functions in logical order
5. **Logging end:** `:log info "=== END: script-name ==="`

### Logging

```routeros
:log info "message"    # For actions: add, update (set), or remove commands
:log debug "message"   # For no-ops: when you skip doing anything (no command executed)
:put "message"         # For console output (visible when running script)
```

**Important:** Updates (`/set` commands) are **actions** and must use `:log info`, not `:log debug`. Only use `:log debug` when you check for existence and skip executing any command.

Note: `:log` writes to log files and isn't visible when running the script. Use `:put` for output visible in the console.

### Terminal Colours

RouterOS supports terminal colors using `/terminal style` commands (undocumented feature). Use colors only where they help distinguish important information:

```routeros
# Success messages
{ [/terminal style varname-local]; :put "OK: Rule exists"; }

# Error messages
{ [/terminal style error]; :put "NOT FOUND: Rule missing!"; }

# Warnings
{ [/terminal style syntax-meta]; :put "WARNING: No active connections"; }
```

Available styles: Use `/terminal style [TAB]` to see all options.

Reference: <https://forum.mikrotik.com/t/script-input-from-console-works/120030/5>

### Functions

Use `:global functionName do={...}` to organise code. No parameters - functions contain all hardcoded values:

```routeros
:global configureDHCP do={
    # All DHCP configuration code here
}

$configureDHCP  # Call the function
```

### Desired State Pattern

Check if configuration exists, then add if missing or update if present:

```routeros
:local id [/ip pool find name="dhcp-pool-bridge"]
:if ([:len $id] = 0) do={
    /ip pool add name="dhcp-pool-bridge" ranges="192.168.88.100-192.168.88.199"
} else={
    /ip pool set $id ranges="192.168.88.100-192.168.88.199"
}
```

### Always Use Quotes for String Values

Always quote string values in RouterOS commands, even when quotes are optional:

```routeros
/ip address find interface="combo1-WAN"
/ip firewall nat find where chain="srcnat" and out-interface="combo1-WAN"
```

### Verification Prints

Print configuration immediately after setting:

```routeros
:put "=== Configuring IP address (expected: combo1-WAN 192.168.200.2/24) ==="
# ... configuration code ...
/ip address print where interface="combo1-WAN"
:put ""
```

### Comments for Rules

Add comments to firewall rules and other named objects for reference:

```routeros
/ip firewall filter add chain="forward" action="accept" protocol="udp" comment="allow-udp"
/ip firewall filter find comment="allow-udp"
```
