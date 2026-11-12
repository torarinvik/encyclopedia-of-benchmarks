# Counting square-free integers

## Contract

Return the number of positive square-free integers not greater than `N`. This local scalar benchmark accepts `1 <= N <= 1,000,000,000,000`; other values return `-1`. The exported C ABI entry point is `int64_t counting_squarefrees(int64_t n);`.

The official Library Checker task allows `N` through `10^18`. This package caps the bound so every port can sieve Möbius values through `floor(sqrt(N))`, at most 1,000,000, with a compact fixed workspace.

## Algorithm and local coverage

The count is evaluated with

`Q(N) = sum_{d <= sqrt(N)} mu(d) * floor(N / d^2)`.

Each port sieves the Möbius values up to `floor(sqrt(N))`, then accumulates the weighted quotients. This takes `O(sqrt(N) log log N)` time and `O(sqrt(N))` auxiliary space.

This is distinct from the existing [`mobius_function`](../../m/mobius_function/README.md), which returns only `mu(N)`, and [`is_square_free`](../../i/is_square_free/README.md), which tests one integer. [`prime_factorization_sieve`](../../p/prime_factorization_sieve/README.md) emits prime factors for an input; it does not count square-free integers in a prefix.

The [official task statement](https://github.com/yosupo06/library-checker-problems/blob/master/number_theory/counting_squarefrees/task.md) defines the count, and its [task parameters](https://github.com/yosupo06/library-checker-problems/blob/master/number_theory/counting_squarefrees/info.toml) set the original `N` bound to `10^18`. The local Python oracle is [`benchmarks/counting_squarefrees_oracle.py`](../../counting_squarefrees_oracle.py).

[`workload.json`](workload.json) covers small exact counts, larger prefixes, the local bound, and invalid inputs.

## Implementations

| Language | Source |
| --- | --- |
| Mojo | [`mojo/c/counting_squarefrees.mojo`](../../../mojo/c/counting_squarefrees.mojo) |
| C | [`c/c/counting_squarefrees.c`](../../../c/c/counting_squarefrees.c) |
| C3 | [`c3/c/counting_squarefrees.c3`](../../../c3/c/counting_squarefrees.c3) |
| C++ | [`cpp/c/counting_squarefrees.cpp`](../../../cpp/c/counting_squarefrees.cpp) |
| Elisa | [`elisa/c/counting_squarefrees.elisa`](../../../elisa/c/counting_squarefrees.elisa) |
| Nim | [`nim/c/counting_squarefrees.nim`](../../../nim/c/counting_squarefrees.nim) |
| Odin | [`odin/c/counting_squarefrees.odin`](../../../odin/c/counting_squarefrees.odin) |
| Rust | [`rust/c/counting_squarefrees.rs`](../../../rust/c/counting_squarefrees.rs) |
| V | [`v/c/counting_squarefrees.v`](../../../v/c/counting_squarefrees.v) |
| Zig | [`zig/c/counting_squarefrees.zig`](../../../zig/c/counting_squarefrees.zig) |
