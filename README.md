# linux-ad-integration-precheck: Summary
Bash script to verify prerequisites for integrating Linux systems with Active Directory, including DNS, packages, connectivity, and system configuration hints.

# Linux AD Integration Precheck

## Overview

This repository provides a shell script that performs pre-integration checks before joining a Linux system (e.g., RHEL 8/9) to an Active Directory (AD) domain using SSSD and Kerberos. It helps system administrators verify that all essential conditions are met to ensure a smooth domain join operation.

## Features

* Verifies that the system is not already joined to a domain
* Confirms FQDN is correctly set
* Checks network reachability and DNS resolution for the specified AD domain controller
* Validates the system's DNS settings point to the AD environment
* Confirms necessary packages are installed (e.g., `sssd`, `oddjob`, `realmd`)
* Warns about potential issues in `nsswitch.conf` or PAM configuration (if applicable)

## Usage

```bash
# Make script executable
chmod +x ad-precheck.sh

# Run script with domain controller FQDN as argument
sudo ./ad-precheck.sh dc.example.com
```

## Requirements

* bash shell
* Common system utilities: `ping`, `dig`, `sssd`, `realm`, `rpm`
* Root privileges to inspect system settings

## Output

The script provides human-readable status messages including:

* ✅ Passed checks
* ⚠️ Warnings for potential misconfigurations
* ❌ Failures that must be addressed

## Example Output

```
✅ Hostname is FQDN: me.example.com
✅ System is not joined to a domain (realm list empty)
✅ Can ping dc.example.com
✅ DNS server points to domain controller
✅ Required packages are installed: sssd, oddjob, realmd
⚠️ Note: /etc/nsswitch.conf should include `sss` for passwd and group
⚠️ Note: PAM configuration will be managed by authselect after join
```

## License

MIT

## Author

Created by momogitater

---

For feedback or contributions, please open an issue or submit a pull request.
