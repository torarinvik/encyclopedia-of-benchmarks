# Open knight tour

The pinned C# and Dart implementations build an `n × n` board and search starting squares in row-major order. From each square they run recursive depth-first search using moves `(+1,+2), (-1,+2), (+1,-2), (-1,-2), (+2,+1), (+2,-1), (-2,+1), (-2,-1)`. A successful board stores visit numbers starting at 1; if no tour exists, the returned board remains all zeroes.

Input is `[n]`, bounded to 1–5. Output is the row-major board encoded as little-endian signed 32-bit integers; return value is bytes written. Malformed input returns -1 and insufficient output capacity returns -2. This preserves the source's first-start/first-path behavior and differs from fixed-start knight-tour contracts.

Runtime oracle: `open_knight_tour_oracle.py`.
