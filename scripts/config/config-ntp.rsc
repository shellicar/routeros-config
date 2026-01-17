# config/ntp
# Configure NTP client and timezone
# policy=read,write

:log info "=== START: config-ntp ==="

:global configureNTP do={
    :put "=== Configuring timezone (Australia/Melbourne) ==="
    /system clock set time-zone-name=Australia/Melbourne
    :put "Set timezone to Australia/Melbourne"
    :log info "Set timezone to Australia/Melbourne"
    :put ""

    :put "=== Configuring NTP client ==="
    /system ntp client set enabled=yes servers=0.au.pool.ntp.org,1.au.pool.ntp.org,2.au.pool.ntp.org,3.au.pool.ntp.org
    :put "Enabled NTP client with Australian pool servers"
    :log info "Enabled NTP client with Australian pool servers"
    :put ""

    :put "=== Current clock settings ==="
    /system clock print
    :put ""

    :put "=== NTP client status ==="
    /system ntp client print
    :put ""
}

$configureNTP

:set configureNTP;

:log info "=== END: config-ntp ==="
