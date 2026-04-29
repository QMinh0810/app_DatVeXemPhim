## Context

The movie booking app requires better data presentation (actors, directors, genres) and a more polished UI for the movie info and seat selection screens. Also, some data mappings like `now_showing` versus `showing` have caused bugs on the Home screen.

## Goals / Non-Goals

**Goals:**
- Provide full relationship data in one API call for movies using PostgreSQL aggregations.
- Replace generic seat IDs with human-readable seat names (e.g., A1, B2).
- Open YouTube trailers externally to avoid app crashes.
- Ensure perfect square ratios in the seat selection grid.
- Restore the `now_showing` status mapping.

**Non-Goals:**
- In-app video player implementation.

## Decisions

- **URL Launcher for Trailers:** We will use the `url_launcher` package to open YouTube app/browser instead of an embedded player. This is much simpler, safer, and less prone to playback issues.
- **PostgreSQL `array_agg`:** We will perform JOINs directly in the `movieController.js` queries to gather `theloai`, `daodien`, and `dienvien` into arrays using `array_agg` to avoid multiple separate queries per movie.
- **Seat Sizing:** Wrap the seat widgets in `AspectRatio(aspectRatio: 1)` or a strict `SizedBox` so they don't stretch irregularly, no matter their status (available/booked/broken).

## Risks / Trade-offs

- **Risk:** SQL JOINs and `array_agg` on multiple many-to-many tables might cause duplicate rows or Cartesian products if not grouped correctly.
  **Mitigation:** We will group by the movie ID and ensure we use `string_agg` or distinct aggregation if necessary.
