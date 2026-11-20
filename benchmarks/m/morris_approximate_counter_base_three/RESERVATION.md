# Reservation: Morris approximate counter with ternary transition scale

**Status:** Ten language ports, independent references, fixtures, documentation, and byte-output runner/verifier registration are present. Ports remain uncompiled and unexecuted by design.

- Owner: `/root/oi_wiki_audit` (ten-language package); `/root` (suite and root-catalog integration).
- Candidate: `morris_approximate_counter_base_three`, from the tunable-parameter section of the Algorithm Archive Approximate Counting chapter.
- Distinctness: this is the same generalized Morris counter family, but the source's `a=1/2` setting changes the per-state transition probability from `2^-v` to `3^-v` and the decoded estimate from `2^v-1` to `(3^v-1)/2`. The benchmark records the materially different transition schedule and estimator as a parameter variant alongside the existing base-2 profile; it does not claim a new counter family.
- Contract: `i64_array_bytes_output`; input `[Q, draw_0, ..., draw_(Q-1)]`, `0<=Q<=30`, each draw in `[0,3^30)`. Start at `v=0`; for each event, increment iff `draw < 3^(30-v)`. Emit `(v,(3^v-1)/2)` as two little-endian signed i64 values. A zero-event tape is valid. Malformed/null input returns `-1`; null or fewer than 16 output bytes returns `-2`, after validating the complete input.
- Bounds: maximum valid input length 31 words, maximum parseable length 32 words, maximum output 16 bytes, workspace 32 bytes. `v<=30`, and the decoded estimate is below signed-i64 limits.
- Complexity: `O(Q)` time and `O(1)` auxiliary state. An independent reference should derive the transition threshold from exact adjacent decoded estimates, rather than call the primary helper.
- Rights: use the chapter and Morris's paper for the algorithm description only. No Archive code, text, examples, tests, or fixtures are copied; ports, contracts, and workloads are independently written.
