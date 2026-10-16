# Nagel–Schreckenberg traffic model

This benchmark ports the pinned Python `simulate` update for a single circular road. Each car accelerates by one up to the maximum speed, is capped by the number of empty cells before the next car minus one, and then moves simultaneously. Random braking is fixed at probability zero so each input has a deterministic result; the source's wrapped gap calculation and update order are retained.

Input is `[cell_count, update_count, max_speed, state_0, ...]`. There are 2–32 cells, 0–16 updates, max speed 0–5, and each initial cell is `-1` (empty) or a speed 0–5. Output contains the initial state and each subsequent state, row-major, encoding empty as byte 0 and speed `s` as byte `s+1`. See `nagel_schrekenberg_oracle.py` for the runtime expected output.
