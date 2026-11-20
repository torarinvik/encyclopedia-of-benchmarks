# Perfect-shuffle order

Count how many repeated perfect out-shuffles restore an even deck of unique
cards to its original order. Input is `[N]`, where `2 <= N <= 10000` and `N`
is even; return the least positive shuffle count, or `-1` for an invalid frame
or deck size.

The primary method simulates the exact half-interleave on a deck containing
labels `0..N-1` until identity returns. Its time is `O(N·T)` and scratch space
is `O(N)`, where `T` is the returned repetition count. The independent
reference computes the multiplicative order of two modulo `N-1`. The out-shuffle
maps all but the fixed final position according to multiplication by two modulo
`N-1`, so the two references use different representations of the same
permutation order. In this bounded domain `T <= N-1`.

[`shuffle_array`](../shuffle_array/README.md) implements a one-step half-interleave,
while this profile asks for the order of that permutation. The local classical
[`shors_algorithm`](../../s/shors_algorithm/README.md) searches multiplicative
orders of supplied bases and uses them to extract factors; it does not compute
the fixed out-shuffle's restoration count. These profiles share operations but
have distinct inputs, outputs, and algorithmic goals.

The [Rosetta Code task](https://rosettagit.org/tasks/perfect-shuffle/) defines
the out-shuffle and supplies seven reference deck sizes. It is used as an idea
and expected-value reference only; the contract, workload, oracle, and ports
are independently authored.

| Language | Port |
|---|---|
| C | [c/p/perfect_shuffle_order.c](../../../c/p/perfect_shuffle_order.c) |
| C3 | [c3/p/perfect_shuffle_order.c3](../../../c3/p/perfect_shuffle_order.c3) |
| C++ | [cpp/p/perfect_shuffle_order.cpp](../../../cpp/p/perfect_shuffle_order.cpp) |
| Elisa | [elisa/p/perfect_shuffle_order.elisa](../../../elisa/p/perfect_shuffle_order.elisa) |
| Mojo | [mojo/p/perfect_shuffle_order.mojo](../../../mojo/p/perfect_shuffle_order.mojo) |
| Nim | [nim/p/perfect_shuffle_order.nim](../../../nim/p/perfect_shuffle_order.nim) |
| Odin | [odin/p/perfect_shuffle_order.odin](../../../odin/p/perfect_shuffle_order.odin) |
| Rust | [rust/p/perfect_shuffle_order.rs](../../../rust/p/perfect_shuffle_order.rs) |
| V | [v/p/perfect_shuffle_order.v](../../../v/p/perfect_shuffle_order.v) |
| Zig | [zig/p/perfect_shuffle_order.zig](../../../zig/p/perfect_shuffle_order.zig) |
