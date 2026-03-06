# Troubleshooting & Incident Resolution Guide
**Project:** Enterprise Student Identity Lifecycle
**Authro:** Kenji Tratnik

This document serves as an analytical log of technical hurdles encountered during the simulation of the Enterprise Help Desk environment. It demonstrates the ability to identify, diagnose, and resolve complex infrastructure and automation incidents.

---

## 1. Automation & Scripting Resolutions

### **Issue: AD Replication Latency (Identity Translation Failure)**
* **Incident:** During student onboarding, the script would fail when applying NTFS permissions, stating: *"Identity references could not be translated."*
* **Root Cause:** Active Directory is a distributed system. The User object was created on one Domain Controller but had not yet replicated to the File Server’s local cache/directory view.
* **Resolution:** Implemented a **Validation Loop** using the `NTAccount.Translate` method. The script now "pings" the directory until the SID is resolvable before proceeding to the ACL phase.

### **Issue: Null Parameter Binding on Cleanup**
* **Incident:** `Remove-Item : Cannot bind argument to parameter 'Path' because it is null.`
* **Root Cause:** A typographical error in variable naming (`$Passwo4rdFile` vs `$PasswordFile`).
* **Resolution:** Audited script logic and synchronized variable naming. Implemented "Pre-Flight" variable definitions to ensure all paths are populated before execution.

### **Issue: Data Integrity & Delimiter Collision**
* **Incident:** Unexpected creation/deletion of a user named "ad".
* **Root Cause:** A comma was used instead of a period in the CSV (`ad,KatCherry`). This caused the CSV parser to shift data columns.
* **Resolution:** Corrected source data. Added a **Data Sanitization** check in the `foreach` loop to skip rows that do not match the expected `ad.*` naming convention.

### **Issue: Missing .NET Type Acceleration**
* **Incident:** `Unable to find type [System.Web.Security.Membership]`
* **Root Cause:** The assembly `System.Web` is not loaded by default in PowerShell Core/5.1.
* **Resolution:** Replaced the legacy .NET call with a custom-built `New-RandomPassword` function using `Get-Random` and character arrays to ensure portability across different Windows environments.

---

## 2. File Services & NTFS Permissions

### **Issues: Unable to Remove "Users" from Folder Security**
* **Incident:** Error message stating permissions cannot be removed because they are inherited from `C:\`.
* **Root Cause:** **NTFS Inheritance** is enabled by default. Since the `C:\` drive grants "Users" read access, every subfolder (`C:\Shares\Faculty`) inherits that permission.
* **Resolution:** 1.  Navigate to **Advanced Security Settings**.
    2.  Select **Disable Inheritance**.
    3.  Choose **"Convert inherited permissions into explicit permissions on this object"** to retain existing admins while allowing the removal of the generic "Users" group.

---

## 3. Cross-Platform Client Connectivity (BYOD)
In a University setting, student laptops cannot be joined to the domain like lab computers. Accessing the `H:` drive requires "Workgroup-to-Domain" authentication.

### **Issue: Password Change Requirement on Non-Domain Devices**
* **Incident:** When mapping a network drive on a non-domain joined (BYOD) Windows VM, the connection fails with: "The user's password must be changed before logging on the first time."
* **Root Cause:** The script creates users with the `ChangePasswordAtLogon` flag set to `$true` for security. However, non-domain joined machines lack the Secure Channel to the Domain Controller required to facilitate an interactive password change via the SMB protocol.
* **Lab Resolution:** For validation purposes, the script was modified to `-ChangePasswordAtLogon $false`.
* **Enterprise Recommendation:* In a production environment, students would satisfy this requirement via a **Web-Based Self-Service Password Reset (SSPR)** portal or **Outlook Web Access (OWA)** prior to mapping their drive.

### **Issue: Error 0x80070035 (Network Path Not Found) via CNAME**
* **Incident:** Client could `ping` the DNS Alias (`files.ad.lab`), but could not map the drive.
* **Root Couse:** **Strict Name Checking** and missing Service **Principal Names (SPN)**. Windows Server, by default, rejects SMB traffic intended for an alias that doesn't match its local hostname.
* **Resolution:**
  * Used `setspn -s host/files Dell-R440` to register the alias in Active Directory.
  * Configured the `OptionalNames` Multi-String value in the Registry (`LanmanServer\Parameters`)
  * Set `DisableStrictNameChecking` to `1`

---

## 4. Summary of Lessons Learned
1. **Environment Awareness:** A script that works for a Domain Admin may fail for a BYOD student due to protocol limitations (like the password change requirement).
2. **Idempotency:** Designing scripts to be "state-aware" (checking if a user exists before creating) prevents environmental "noise" and duplicate errors.
3. **Abstraction:** Using DNS CNAMEs for file shares is an enterprise best practice that decouples services from physical hardware, simplifying future migrations.



