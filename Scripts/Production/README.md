# Script Documentation

## Execution Instructions
1. Open PowerShell as **Administrator**.
2. Ensure the execution policy allows local scripts: `Set-ExecutionPolicy RemoteSigned -Scope Process`.
3. Run the Provisioning script: `.\Production\BulkStudentProvision.ps1`.

## Script Inventory
| Script | Purpose | Run Frequency |
| :--- | :--- | :--- |
| **BulkStudentProvision.ps1** | Provisioning/Deprovisioning based on CSV. | On-Demand / Scheduled |
| **Cleanup-Lab.ps1** | Resets the AD environment for testing. | Lab Use Only |

## Dependencies
* **Active Directory Module:** Required for all AD commands.
* **Permissions:** Must be run by an account with 'Domain Admin' or delegated OU permissions.
