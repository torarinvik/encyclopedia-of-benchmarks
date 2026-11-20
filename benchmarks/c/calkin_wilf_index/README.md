# Calkin–Wilf indexed rational

Return the positive reduced rational at one-based breadth-first index `k` in
the Calkin–Wilf tree. Input is `[k]`, with `1 <= k < 2^62`; length two is
parseable only to reject a trailing word. Output is the numerator and
denominator as two little-endian signed i64 words. Success returns 16; invalid
or null input returns `-1`, and a null or short output returns `-2` after input
validation without writing.

Start at `1/1` and scan the bits of `k` after its leading one. For a zero bit,
replace `(a,b)` with `(a,a+b)`; for a one bit, replace it with `(a+b,b)`.
This requires `O(log k)` time and `O(1)` space. With at most 61 transitions,
the Fibonacci bound keeps both components at most `6,557,470,319,842`, well
within signed 64-bit range. An alternating-bit maximum-depth workload reaches
this bound.
The independent reference computes consecutive values of Stern's diatomic
sequence, giving the same fraction without constructing a tree.

The existing [`stern_brocot_tree`](../../s/stern_brocot_tree/README.md) carries
neighbor bounds and supports rational path, ancestor, and interval queries;
it does not compute the breadth-first Calkin–Wilf indexed rational. The
existing [`continued_fraction`](../continued_fraction/README.md) converts a
given rational to coefficients rather than decoding an index. The
[CP-Algorithms continued-fraction article](https://cp-algorithms.com/algebra/continued-fractions.html)
describes the Calkin–Wilf tree. This package uses mathematical ideas only;
its contract, code, and fixtures are independently authored.

Contract, references, ten language drafts, workload, rights note, package
checker, and byte-output suite wiring are drafted. The verifier specifies
small indices and power-of-two boundaries. No programs or checks have been
run; all drafts remain unverified.
