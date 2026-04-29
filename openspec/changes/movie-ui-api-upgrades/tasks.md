## 1. Backend APIs

- [x] 1.1 Update `getMovies` and `getMovieById` in `backend/controllers/movieController.js` with JOINs and `array_agg` for relationships.
- [x] 1.2 Update `getHotMovies` and `searchMovies` in `movieController.js` with the same JOINs.
- [x] 1.3 Update `getBookingHistory` in `backend/controllers/userController.js` to JOIN `ghengoi` and map `tenGhe`.

## 2. Flutter Models

- [x] 2.1 Add `directors`, `actors` properties to `lib/models/movie_model.dart`.
- [x] 2.2 Update `fromJson` in `movie_model.dart` to parse `directors`, `actors`, and `genres` from the new API structure.

## 3. UI Layout

- [x] 3.1 Add `url_launcher` to `pubspec.yaml`.
- [x] 3.2 Redesign `lib/screens/movie_info_screen.dart` (trailer thumbnail at top, poster on left, duration converted to h m).
- [x] 3.3 Implement Trailer Play button using `url_launcher`.
- [x] 3.4 Display `directors`, `actors`, and `genres` list in `movie_info_screen.dart` (or "Đang cập nhật" if empty).
- [x] 3.5 Update `lib/screens/payment_screen.dart` to show seat names (e.g., A1, A2) instead of UUIDs.
- [x] 3.6 Update `lib/screens/my_tickets_screen.dart` to show `tenGhe`.
- [x] 3.7 Add `AspectRatio(aspectRatio: 1)` in `lib/screens/seat_selection_screen.dart` to enforce square seats.

## 4. Logic Fixes

- [x] 4.1 Revert movie status in `lib/viewmodels/movie_viewmodel.dart` and `home_screen.dart` from `showing` back to `now_showing`.
