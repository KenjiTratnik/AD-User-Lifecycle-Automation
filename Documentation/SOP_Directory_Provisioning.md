# SOP: Student Directory & Identity Provisioning
**System:** Enterprise Lab Environment (Simulation)

**Target:** Windows Server 2019 / Active Directory Domain Services

**Author:** Kenji Tratnik

### 1. Summary
This document outlines the end-to-end configuration for an automated student identity and home directory provisioning system. This infrastructure supports high-density student populations (BYOD and Lab-joined) using a hardware-agnostic design.

---

## 2. Active Directory Infrastructure
### 2.1 Organzational Unit (OU) Hierarchy
To maintain the Principle of Least Privilege (PoLP) and ease of GPO application, the following structure was created:
* `OU=Enterprise`
    * `OU=Users`
        * `OU=Students` (Target for active accounts)
        * `OU=DisabledStudents` (Target for offboarded accounts)
    * `OU=Groups` (Contains `SG_Students_Share`)

### 2.2 Security Group Configuration
The **SG_Students_Share** group is used for "Share Level" access.
* **Scope:** Global
* **Type:** Security
* **Purpose:** Grants initial entry to the SMB share; specific folder access is then handled via NTFS.

---

## 3. Storage & File Services
### 3.1 Share Configuration
* **Local Path:** `C:\Shares\StudentHomes`
* **Share Name:** `StudentHomes` (Hidden share used for production)
* **Share Permissions:** `Everyone: Full Control` (Security is managed via the NTFS layer).
* **Access-Based Enumeration (ABE):** Enabled. This ensures students only see their own folder when browsing the root share.

### 3.2 Service Absraction (DNS CNAME)
To ensure the infrastructure is hardware-agnostic, a DNS Alias was implemented:
* **CNAME:** `files.ad.lab` → points to `Dell-R440.ad.lab`.
* **Registry Hardening:** * `DisableStrictNameChecking` set to `1`.
    * `OptionalNames` Multi-String set to `files` and `files.ad.lab`.
* **SPN Registration:** ```powershell
    setspn -s host/files Dell-R440
    setspn -s host/files.ad.lab Dell-R440
    ```

---

## 4. Automation Logic (BulkStudentProvision.ps1)
The provisioning script handles the full **Identity Lifecycle**:

1. **Pre-Flight:** Validates CSV integrity and clears previous password logs.
2. **Onboarding:**
    * Generates high-entropy 14-character passwords.
    * Creates AD User with UPN (`username@ad.lab`).
    * Sets Home Directory attributes for automatic drive mapping.
3. **AD Replication Loop:**
    * Implements a retry-logic loop to ensure the user object is globally resolvable before applying NTFS permissions.
4. **Offboarding:**
    * Detects `Graduated = Yes` in CSV.
    * Disables account, strips non-essential group memberships, and moves object to `OU=DisabledStudents`.

---

## 5. Client Connectivity (BYOD)
### 5.1 Manual Mapping (Non-Domain Joined)
For student-owned hardware, the drive is mapped using the following parameters:
* **Drive Letter:** `H:`
* **Path:** `\\files.ad.lab\StudentHomes\ad.Username`
* **Credential Format:** `AD\ad.Username` or `ad.Username@ad.lab`

### 5.2 Password Requirement Workaround
For the simulation of BYOD devices (which cannot interactively change AD passwords via SMB), the `ChangePasswordAtLogon` flag must be manually satisfied via a domain-joined machine or cleared for testing. In production, an **SSPR Web Portal** is required.

---

## 6. Verification & Auditing
Every run of the provisioning script generates a timestamped log:
* **Log Location:** `C:\Provisioning\Logs\Provisioning_YYYYMMDD_HHmm.log`
* **Command:** `Start-Transcript` / `Stop-Transcript`





