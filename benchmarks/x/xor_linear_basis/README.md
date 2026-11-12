# Incremental XOR linear basis

This package processes an ordered operation stream over nonnegative 63-bit
integers. Operation `0,x` inserts `x`; operation `1` reports the largest XOR
obtainable from any subset of values inserted so far; operation `2,x` reports
whether `x` is obtainable. The empty subset is allowed, so zero is always
representable and the maximum starts at zero.

## Method and bounded profile

The basis keeps one pivot for each possible highest set bit. Insertion scans
from bit 62 down: it eliminates a pivot when present or stores the reduced
value at the first missing pivot. Membership reduces a query in the same order.
The maximum-subset-XOR query greedily accepts a pivot exactly when XORing it
increases the current value. Each update or query costs `O(63)` time with
`O(63)` pivot storage.

The input is `[Q,(0,x | 1 | 2,x)...]`, with `1 <= Q <= 64`,
`0 <= x <= 2^63-1`, and at most 16 insert operations. The insertion cap keeps
the independent exhaustive oracle bounded by `2^16` subsets. The maximum valid
input uses 129 words; one additional parseable word is allowed only to reject
trailing input.

Each query returns one little-endian signed 64-bit word, either a maximum XOR
or membership bit. At most 64 queries use 512 bytes. Invalid input returns
`-1`; a null or undersized output buffer returns `-2` when at least one result
must be written. A valid insertion-only sequence returns zero bytes and permits
a null output pointer. `workspace.bytes` denotes the maximum output capacity;
the basis and staged result words use separate bounded storage.

This is an incremental linear-basis workload. It differs from solving general
GF(2) equations and from intersecting two vector spaces, which are separate
contracts in the repository.

The primary oracle maintains all subset XORs explicitly after each insertion.
The independent checker enumerates the subset masks afresh at each query. Both
are bounded by the 16-insertion limit. The package-local
[`verify_xor_linear_basis_package.py`](verify_xor_linear_basis_package.py)
statically checks metadata, fixtures, certificates, and port inventory.

Algorithm idea reference: [OI Wiki — Linear Basis](https://www.timothywang.ca/OI-wiki/math/linear-algebra/basis/).
The implementation is clean-room; no source code or explanatory prose is
reproduced.

## Implementations

| Language | Source |
|---|---|
| C | [`c/x/xor_linear_basis.c`](../../../c/x/xor_linear_basis.c) |
| C3 | [`c3/x/xor_linear_basis.c3`](../../../c3/x/xor_linear_basis.c3) |
| C++ | [`cpp/x/xor_linear_basis.cpp`](../../../cpp/x/xor_linear_basis.cpp) |
| Elisa | [`elisa/x/xor_linear_basis.elisa`](../../../elisa/x/xor_linear_basis.elisa) |
| Mojo | [`mojo/x/xor_linear_basis.mojo`](../../../mojo/x/xor_linear_basis.mojo) |
| Nim | [`nim/x/xor_linear_basis.nim`](../../../nim/x/xor_linear_basis.nim) |
| Odin | [`odin/x/xor_linear_basis.odin`](../../../odin/x/xor_linear_basis.odin) |
| Rust | [`rust/x/xor_linear_basis.rs`](../../../rust/x/xor_linear_basis.rs) |
| V | [`v/x/xor_linear_basis.v`](../../../v/x/xor_linear_basis.v) |
| Zig | [`zig/x/xor_linear_basis.zig`](../../../zig/x/xor_linear_basis.zig) |
