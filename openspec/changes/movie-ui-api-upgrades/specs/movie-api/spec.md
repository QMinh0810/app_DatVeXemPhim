## ADDED Requirements

### Requirement: Enhanced Movie Payload
The system MUST return related entities (directors, actors, genres) in a single API call when fetching movies.

#### Scenario: User fetches movies
- **WHEN** the frontend calls `getMovies`, `getMovieById`, `getHotMovies`, or `searchMovies`
- **THEN** the API returns JSON objects containing `directors`, `actors`, and `genres` as arrays of strings.

### Requirement: Seat Names in History
The system MUST return human-readable seat names in booking history.

#### Scenario: User views booking history
- **WHEN** the frontend calls `getBookingHistory`
- **THEN** the API returns tickets containing a `tenGhe` property (e.g., "A1") formed by joining `maHangGhe` and `soGhe`.
