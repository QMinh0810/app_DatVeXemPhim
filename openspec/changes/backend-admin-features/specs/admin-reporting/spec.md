## ADDED Requirements

### Requirement: Monthly Excel Reports
The system MUST generate monthly statistical reports in Excel format (`.xlsx`) instead of PDF.

#### Scenario: Admin requests monthly report
- **WHEN** admin requests the monthly report endpoint
- **THEN** the system generates and returns a downloadable `.xlsx` file containing revenue data

### Requirement: Daily Revenue Statistics
The system MUST provide daily aggregated revenue data including ticket sales and F&B.

#### Scenario: Admin views daily stats
- **WHEN** admin calls the daily revenue stats endpoint
- **THEN** the system returns an aggregation of revenue grouped by date

## MODIFIED Requirements
*(None)*
