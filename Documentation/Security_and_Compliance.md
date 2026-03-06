# Security & Compliance Framework: Student Identity Lifecycle
**Author:** Kenji Tratnik
**Scope:** Active Directory Domain Services & NFTS File Security

## 1. Principle of Least Privilege (PoLP)
The core security philosophy of this project is ensuring that users have the minimum level of access necessary to perform their functions.

* **Explicit Group Access:** Inherited "Authenticated Users" and "Users" permissions were removed from the root `C:\Shares` directory.
* **Role-Based Access Control (RBAC):** Access is granted strictly through Global Security Groups (e.g., `SG_Students_Share`).
* **Siloed Home Directories:** Each student is granted **Full Control** only over their specific home directory. This prevents horizontal traversal where one student could view or modify another's data.

## 2. Password Policy & Entropy
To align with modern cybersecurity standards and reduce Help Desk ticket volume, the provisioning script implements a high-entropy password generation function.

* **Complexity Requirements:** Every generated password is 14 characters long and satisfies the four-point complexity check (Uppercase, Lowercase, Numbers, and Symbols).
* **Ambiguity Filtering:** To prevent "Login Denied" incidents caused by visual character confusion, the following characters are programmatically excluded from all passwords:
  * `0` (Zero) and `O` (Capital O)
  * `1` (One), `l` (Lowercase L), and `I` (Capital I)
* **Forced Reset:** All accounts are created with the `ChangePasswordAtLogon` flag set to `$true`, ensuring the administrative "temporary" password is replaced by a private user-defined secret immediately.

## 3. Account Lifecycle & Retention (Offboarding)
Universities must balance security with data retention requirements. This project automates the transition from "Active" to "Archived" status.

* **Account Hardening:** Upon graduation, accounts are immediately **Disabled** rather than deleted. This prevents unauthorized access while maintaining the object's SID for audit logs.
* **Organizational Migration:** Objects are moved to the `OU=DisabledStudents` container. This segments the directory and ensures that GPOs applied to active students (like Drive Mapping) no longer apply to inactive accounts.
* **Access Revocation:** The script dynamically strips all security group memberships. This eliminates "Permission Creep," ensuring that if an account is ever re-enabled, it does not retain legacy access to sensitive departmental shares.

## 4. Operational Integrity (Idempotency)
To ensure system stability, the automation logic is **Idempotent**.

* **State-Aware Execution:** Before performing any "Write" action (Create, Move, or Disable), the script validates the current state of the Active Directory object.
* **Error Prevention:** This prevents "Object Already Exists" or "Parent is Instantiated" errors, allowing the script to be run repeatedly against a master CSV without causing system instability or duplicate entries.

## 5. Auditability
* **Secure Logging:** Every provisioning action is recorded in a local administrative log (`NewStudentPasswords.csv`).
* **Transcripting:** In a production environment, this suite is designed to run within a `Start-Transcript` block to provide a timestamped audit trail of every modification made to the Domain Controllers.
