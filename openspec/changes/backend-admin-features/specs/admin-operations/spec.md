## ADDED Requirements

### Requirement: Update Seat Status
The system MUST allow administrators to update the status of individual seats to handle maintenance.

#### Scenario: Admin marks seat as broken
- **WHEN** admin sends a PUT request to update seat status to `hỏng`
- **THEN** the system updates the `loaighe` in the database to `hỏng` and returns a success message

### Requirement: Automate Showtime Calculation
The system MUST automatically calculate the showtime end time (`gioKetThuc`) based on the movie's duration.

#### Scenario: Admin creates a new showtime
- **WHEN** admin creates a showtime providing only the start time (`gioChieu`)
- **THEN** the system retrieves the movie duration, adds 15 minutes of padding, and sets the calculated end time automatically

### Requirement: Payment Status Override
The system MUST allow administrators to override payment statuses for transactions.

#### Scenario: Admin sets payment to pending
- **WHEN** admin sends a PUT request to update payment status to `pending`
- **THEN** the system updates the transaction status accordingly

## REMOVED Requirements

### Requirement: Regenerate Room Seats
**Reason**: Replaced by individual seat status updates to prevent accidental data loss.
**Migration**: Use the new seat status API instead.

### Requirement: Admin Update Customer
**Reason**: Outdated functionality no longer needed in the admin panel.
**Migration**: N/A
