## ADDED Requirements

### Requirement: External Trailer Playback
The system MUST open movie trailers using an external application or browser.

#### Scenario: User clicks trailer
- **WHEN** the user taps the Trailer button on the Movie Info screen
- **THEN** the `url_launcher` plugin opens the YouTube link.

### Requirement: Redesigned Movie Info Screen
The system MUST display the movie info according to the new layout.

#### Scenario: User views movie details
- **WHEN** the user navigates to the movie info screen
- **THEN** the screen displays a trailer thumbnail on top, poster on the left, duration formatted in "h m", and lists of actors/directors.

### Requirement: Uniform Seat Grid
The system MUST display all seats as perfect squares in the selection grid.

#### Scenario: User views seat map
- **WHEN** the user opens the seat selection screen
- **THEN** every seat widget maintains a 1:1 aspect ratio.

### Requirement: Readable Seat Identifiers
The system MUST display readable seat names.

#### Scenario: User checks out
- **WHEN** the user is on the payment or tickets screen
- **THEN** selected seats are displayed as "A1, A2" instead of generic UUIDs.

### Requirement: Home Screen Data Mapping
The system MUST accurately map the `now_showing` status.

#### Scenario: User views home screen
- **WHEN** the app loads the Home screen
- **THEN** movies with status `now_showing` in the database are correctly displayed in the "Phim đang chiếu" section.
