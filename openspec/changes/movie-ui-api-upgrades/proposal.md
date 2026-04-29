## Why

We need to improve the user interface for the Movie Info screen, properly display seat names instead of IDs, fix seat grid alignment issues, and enhance the movie API to return full relationship data (directors, actors, genres). Using `url_launcher` for trailers is preferred for simplicity and reliability.

## What Changes

- Modify `movieController.js` to use `array_agg` and JOINs for fetching full movie details (genres, directors, actors).
- Modify `userController.js` to fetch seat names (`tenGhe`) for booking history.
- Update Dart `movie_model.dart` to parse new list fields.
- Use `url_launcher` in Flutter for YouTube links.
- Redesign `movie_info_screen.dart` with trailer thumbnail, new layout, and detailed list.
- Update `payment_screen.dart` and `my_tickets_screen.dart` to show seat names.
- Fix `seat_selection_screen.dart` using `AspectRatio(aspectRatio: 1)` to keep seats perfectly square.
- Fix `home_screen.dart` and viewmodel to map `now_showing` instead of `showing` to align with the actual database data.

## Capabilities

### New Capabilities
- `movie-api`: Enhanced data payload for movies and tickets.
- `ui-ux-enhancements`: Upgraded UI for info, seats, and home screens.

### Modified Capabilities
- N/A

## Impact

- `backend/controllers/movieController.js`
- `backend/controllers/userController.js`
- `lib/models/movie_model.dart`
- `lib/viewmodels/movie_viewmodel.dart`
- `lib/screens/movie_info_screen.dart`, `seat_selection_screen.dart`, `payment_screen.dart`, `my_tickets_screen.dart`, `home_screen.dart`
- Dependencies: adding `url_launcher`.
