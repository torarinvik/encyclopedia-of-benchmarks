# Multiply-shift universal hash trace

This profile evaluates the Dietzfelbinger–Hagerup–Katajainen–Penttonen
multiply-shift family on a supplied sequence of keys and odd multipliers.
For a 32-bit key word `x`, an odd 32-bit multiplier `a`, and an output width
`s`, it returns

`h_a(x) = ((a*x) mod 2^32) div 2^(32-s)`.

The bounded frame is `[s,q,(a0,x0),...,(a(q-1),x(q-1))]`, where
`1<=s<=16`, `0<=q<=32`, each multiplier is odd and in
`[1,2^32-1]`, and each key is in `[0,2^32-1]`. The maximum valid frame has
66 signed-i64 words; a 67-word frame is parseable to reject trailing data.
Each query emits one hash as an eight-byte little-endian i64, so the maximum
output is 256 bytes. Input is fully validated before output-pointer and
capacity checks. Invalid input returns `-1`; a null output or insufficient
capacity returns `-2` without writing. A zero-query frame succeeds with a
zero-byte result and permits a null output pointer.

The trace performs one fixed-width multiply and high-bit extraction per
query, so the measured kernel is linear in the number of supplied key and
multiplier pairs.

The primary reference performs one widened 64-bit multiplication, masks the
low 32 bits, and extracts the requested high bits. The independent reference
computes the 32-bit modular product with a fixed 32-round add-and-double
process. Both apply independent validation and framing logic. The bound is
small enough that the entire mathematical product of two 32-bit operands
fits in an unsigned 64-bit integer in every port.

This is distinct from the local [Pearson hash](../pearson_hash/README.md),
which uses a caller-supplied byte permutation in the recurrence
`h = T[h XOR c]`, and from [Zobrist hashing](../zobrist_position_hash_trace/README.md),
which XORs caller-supplied feature keys. It is also distinct from the DADS
[multiplication method](https://xlinux.nist.gov/dads/HTML/multiplicationMethod.html),
which multiplies by an irrational constant modulo one. Existing hash-map
benchmarks measure collision-resolution policies rather than this hash
function family.

The primary source is Dietzfelbinger, Hagerup, Katajainen, and Penttonen,
[“A Reliable Randomized Algorithm for the Closest-Pair Problem”](https://doi.org/10.1006/jagm.1997.0873),
*Journal of Algorithms* 25(1), 19–51 (1997). The [NIST DADS unified
index](https://xlinux.nist.gov/dads/ui.html) and [multiplication-method
entry](https://xlinux.nist.gov/dads/HTML/multiplicationMethod.html) led to
the source audit. See [RIGHTS.md](RIGHTS.md) for provenance and reuse notes.

The deterministic fixture supplies family parameters directly. It does not
sample random odd multipliers, and its outputs make no empirical or
probabilistic claim about collision rates.

## Language ports

| Language | Source |
|---|---|
| C | [`c/m/multiply_shift_universal_hash_trace.c`](../../../c/m/multiply_shift_universal_hash_trace.c) |
| C3 | [`c3/m/multiply_shift_universal_hash_trace.c3`](../../../c3/m/multiply_shift_universal_hash_trace.c3) |
| C++ | [`cpp/m/multiply_shift_universal_hash_trace.cpp`](../../../cpp/m/multiply_shift_universal_hash_trace.cpp) |
| Elisa | [`elisa/m/multiply_shift_universal_hash_trace.elisa`](../../../elisa/m/multiply_shift_universal_hash_trace.elisa) |
| Mojo | [`mojo/m/multiply_shift_universal_hash_trace.mojo`](../../../mojo/m/multiply_shift_universal_hash_trace.mojo) |
| Nim | [`nim/m/multiply_shift_universal_hash_trace.nim`](../../../nim/m/multiply_shift_universal_hash_trace.nim) |
| Odin | [`odin/m/multiply_shift_universal_hash_trace.odin`](../../../odin/m/multiply_shift_universal_hash_trace.odin) |
| Rust | [`rust/m/multiply_shift_universal_hash_trace.rs`](../../../rust/m/multiply_shift_universal_hash_trace.rs) |
| V | [`v/m/multiply_shift_universal_hash_trace.v`](../../../v/m/multiply_shift_universal_hash_trace.v) |
| Zig | [`zig/m/multiply_shift_universal_hash_trace.zig`](../../../zig/m/multiply_shift_universal_hash_trace.zig) |

Package artifacts include the bounded [workload](workload.json), two
independent references, [rights note](RIGHTS.md), and static
[inventory](INVENTORY.md). The shared byte-output suite and catalog register
the primary and independent references, workload fixtures, and package
metadata.
