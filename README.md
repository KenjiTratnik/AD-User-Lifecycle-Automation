# AD-User-Lifecycle-Automation

## Project Overview
This repository contains a professional-grade PowerShell automation suite designed for **Enterprise Identity & Access Management (IAM)**. The lab simulates a University environment where students accounts are managed through their entire lifecycle - from initial enrollment to graduation.

### **Key Insitutional Benefits**
* **Scabability:** Transitions manual "one-by-one" administtration into a data-driven service delivery model.
* **Security Compliance:** Implements the **Principle of Least Privilege (PoLP)** through automated NTFS inheritance and security group auditing.
* **Operational Resiliency:** Solves distributed system issues like AD replication latency via automated validation loops.

---

## Core Features

### 1. Automated Provisioning (Onboarding)
The engine ingests a `students.csv` source of truth to perform the following:
* **Smart Passwords:** Generates 14-character complex passwords excluding ambiguous characters (0, O, 1, l) to reduce Help Desk "Login Failure" tickets.
* **Identity Resolution:** Employs a `while` loop to verify AD replication before attempting to assign folder permissions, preventing "Identity Reference" errors.
* **Resource Siloing:** Automatically provisions Home Folders and assigns granular NTFS permissions/Share paths.

### 2. Graduation Logic (Offboarding)
A state-aware process that handles students marked as `Graduated`
* **Account Hardening:** Disables the account and migrates the object to a `DisabledStudents` OU.
* **Access Revocation:** Strips all Security Group memberships to prevent "Access Creep."
* **Idempotency:** Checks current object status before execution to prevent redundant system errors.

---

## Infrastructure Walkthrough
The lab environment was configured with a hardened directory structure:
1. **Directory Design:** Redirected default user/computer containers using `redircmp` and `redirusr`.
2. **RBAC Model:** Implemented Role-Based Access Control via Global Security Groups.
3. **File Services:** Centralized departmental shares with NTFS "Modify" rights for students and "Full Control" Share permissions.
4. **Group Policy:** Automated drive mapping (`H:`) via Group Policy Preferences (GPP).

---

## Repository Structure
| File/Folder | Description |
| :--- | :--- |
| `/Scripts` | Contains the primary Provisioning and Cleanup scripts. |
| `/Templates` | Sample `students.csv` for lab testing. |
| `SOP.md` | Standard Operating Procedure and Technical Walkthrough. |

---

## Troubleshooting & Resolution
One significant challenge addressed was **AD Replication Latency**. In an enterprise environment, a user created on one Domain Controller may not be immediately resolvable by the File Server. This project solves this by using an **NTAccount Translation Validation Loop**, ensuring the system "waits" for the identity to exist before applying security descriptors.

---

## Author
**Kenji Tratnik**

[![Email](https://img.shields.io/badge/Email-D14836?style=for-the-badge&logo=gmail&logoColor=white)](mailto:kctratnik@gmail.com)  [![LinkedIn](https://img.shields.io/badge/LinkedIn-%230077B5.svg?style=for-the-badge&logo=linkedin&logoColor=white)](https://www.linkedin.com/in/kenji-tratnik-82048528b/)

