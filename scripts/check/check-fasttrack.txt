# check/fasttrack
# Display fasttrack firewall rules and forward chain order
# policy=read

# Check for fast-track rule (should be first)
/ip firewall filter print where chain=forward and action=fasttrack-connection

# Check for accept rule with established,related (should be second)
/ip firewall filter print where chain=forward and action=accept and connection-state="established,related"

# List all forward chain rules to see order
/ip firewall filter print where chain=forward
