# Minimum rotation with a suffix automaton

Return the lexicographically smallest cyclic rotation of a nonempty byte
sequence. Input is `[n, byte_0, ..., byte_(n-1)]`, with `1 <= n <= 256`,
each byte in `0..255`, and exact length `n+1`. At most 258 words are
parseable. Invalid or null input returns `-1`. A null or undersized output
returns `-2` after input validation, with no writes. On success, write the
rotated sequence as exactly n bytes and return n.

Build a suffix automaton for the doubled input. Starting from its initial
state, repeatedly follow the smallest labeled outgoing edge, collecting
exactly n bytes. Every length-n path from the initial state spells a substring
of the doubled sequence and therefore a rotation. The greedy path is the
smallest such string.

The bounded dense transition table stores at most 1024 states with 256
transitions each. For alphabet size A and input length n, construction takes
O(A*n) time when cloning dense states; the greedy walk takes O(A*n) in the
worst case, with O(A*n) space. Here A=256. The O(n) Duval scan and the O(n)
two-candidate method already in the repository compute the same result with
materially different state and operations.

The current fixed-capacity drafts initialize all 1024 state slots, so their
actual per-call initialization work is O(1024*A), even for short inputs.

The [CP-Algorithms suffix-automaton article](https://cp-algorithms.com/string/suffix-automaton.html)
describes this reduction. Its text is licensed CC BY-SA 4.0; only mathematical
ideas are used. The contract, code, and fixtures are independently authored.
The direct-rotation reference, ten language sources, workload, package checker,
and byte-output suite wiring are drafted. The verifier source specifies
exhaustive small binary inputs, full-size sequences, and error probes. Nothing
has been compiled or executed; all drafts remain unverified.
The workload also includes a full-length rotation with two long matching runs
separated by different low symbols.
