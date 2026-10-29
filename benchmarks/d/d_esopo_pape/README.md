# D'Esopo–Pape shortest paths

D'Esopo–Pape is a label-correcting shortest-path method for directed graphs with nonnegative edge weights. The algorithm follows the deque rule described by [CP-Algorithms](https://cp-algorithms.com/graph/desopo_pape.html): a vertex receiving its first queue insertion goes to the tail; after a vertex has been removed once, a later insertion goes to the head. A membership flag prevents duplicate simultaneous queue entries. The [academic label-correcting discussion](https://web.mit.edu/dimitrib/www/SLF.pdf) describes Pape's 1974 method and its potentially exponential worst-case iteration count; this benchmark makes no polynomial worst-case claim for it. A FIFO label-correcting profile such as the local MiBench network workload does not use this Pape deque ordering.

## Contract

The exported function is `d_esopo_pape(const int64_t *values, size_t length, uint8_t *output, size_t capacity)`. Its signed-64-bit input is `[n, m, source, (u, v, weight)...]`, with directed arcs, `1 <= n <= 16`, `0 <= m <= 64`, valid zero-based vertices, and integer weights from 0 through 1000. Self-loops and parallel arcs are allowed. Input length must be exactly `3 + 3*m`; the maximum is 195 values. The packed graph is caller-owned.

Success writes one signed 64-bit distance per vertex, in vertex order, as little-endian bytes and returns `8*n`. Unreachable vertices are encoded as -1. Invalid or null input returns -1. Null output or insufficient output capacity returns -2 after the full graph has been validated, so malformed graph input takes precedence. Errors write no output bytes. The maximum output is 128 bytes. With these limits, every reachable shortest path is small enough to fit in signed 64-bit storage.

## Method and bounds

The ports use forward-star adjacency arrays and a fixed circular deque with at most one queued copy of each vertex. Each deque push, pop, and membership update costs O(1), and storage is O(n+m). Total relaxation work is proportional to the edges scanned over the algorithm's actual sequence of deque removals: `O(n + m + sum(outdegree(v) for every removal of v))`. The number of removals is not claimed to have a polynomial worst-case bound for the original Pape rule. Nonnegative bounded weights ensure the result is well-defined; the benchmark's small input caps keep the workload bounded in practice.

The independent package oracle uses Bellman–Ford, rather than reproducing the deque policy. `workload.json` covers unreachable vertices, a nonzero source, re-entry to the deque front, zero weights, loops and parallel arcs, the vertex and edge limits, malformed inputs, and output errors. `verify_d_esopo_pape.py` statically checks the workload against the oracle and confirms all nine source paths; it does not compile or run benchmark ports.

