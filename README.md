# RUpdater
Keeps your R package up to date
README – R Auto Update Script
📌 Best Use Cases

This script is ideal for:

Keeping R up to date automatically (no more manual downloads).

Updating all R packages after upgrading.

Cleaning old versions to save disk space.

Maintaining consistency across multiple PCs.

Automating updates in organizations, labs, or classrooms.

Running as a scheduled task to keep systems always updated.

📝 What This Script Does

This PowerShell script:

Checks if R or RStudio is running → Stops if they are, to avoid problems.

Finds the latest R version from the official CRAN site.

Checks your installed versions to see if you already have the latest.

If outdated:

Downloads the latest installer.

Installs it silently (no popups, no user input needed).

Deletes older R versions to avoid clutter.

Creates an R script to update all packages.

Runs the R script silently using Rscript.exe.

Cleans up temporary files when finished.

Writes everything to a log file so you can review actions later.

⚙ How to Use
1. Save the Script

Save the provided PowerShell script as:

Update_R.ps1

2. Run It

Open PowerShell as Administrator and run:

.\Update_R.ps1

📂 Log File Location

All actions are recorded in:

C:\Program Files\R\R_Update_Log_<YourComputerName>.txt


You can check this file to see:

When updates were done

What packages were updated

Any errors or warnings

🛠 Requirements

Windows OS with PowerShell

Internet connection

Admin rights to install software

🔒 Safety Features

Prevents updates if R or RStudio are running

Automatically deletes log file if it grows above 5MB

Removes old R versions after installing new one

📊 Script Workflow Diagram
 ┌─────────────────────────────────────────┐
 │ Start Script                            │
 └─────────────────────────────────────────┘
                    │
                    ▼
 ┌─────────────────────────────────────────┐
 │ Check if R or RStudio is running        │
 │  → If running → Exit                    │
 └─────────────────────────────────────────┘
                    │
                    ▼
 ┌─────────────────────────────────────────┐
 │ Create Temp Folder for Installer        │
 └─────────────────────────────────────────┘
                    │
                    ▼
 ┌─────────────────────────────────────────┐
 │ Fetch latest R version from CRAN        │
 └─────────────────────────────────────────┘
                    │
                    ▼
 ┌─────────────────────────────────────────┐
 │ Check installed R versions              │
 │  → If latest installed → Skip download  │
 └─────────────────────────────────────────┘
                    │
                    ▼
        ┌────────────────────────────┐
        │ Download latest R installer │
        └────────────────────────────┘
                    │
                    ▼
        ┌────────────────────────────┐
        │ Install R silently          │
        └────────────────────────────┘
                    │
                    ▼
 ┌─────────────────────────────────────────┐
 │ Delete all old R installations          │
 └─────────────────────────────────────────┘
                    │
                    ▼
 ┌─────────────────────────────────────────┐
 │ Create R script to update packages      │
 └─────────────────────────────────────────┘
                    │
                    ▼
 ┌─────────────────────────────────────────┐
 │ Run R package update script silently    │
 └─────────────────────────────────────────┘
                    │
                    ▼
 ┌─────────────────────────────────────────┐
 │ Clean up temporary files                │
 └─────────────────────────────────────────┘
                    │
                    ▼
 ┌─────────────────────────────────────────┐
 │ Log success message & End               │
 └─────────────────────────────────────────┘

💡 Example Usage in Real Life

Scenario:
You manage 20 Windows PCs used by R data analysts. You want them all running the latest R version with up-to-date packages.

Solution:

Save this script on each PC or a shared network drive.

Use Windows Task Scheduler to run it monthly.

The script will:

Install the newest R version

Remove old versions

Update all packages

Keep a detailed log

Result → All PCs stay updated without manual work.
