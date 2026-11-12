# Summatory Euler totient function

## Contract

Return `sum(phi(i), i=1..N) mod 998244353`. This bounded scalar benchmark accepts `1 <= N <= 1,000,000,000`; other values return `-1`. The exported C ABI entry point is `int64_t sum_of_totient_function(int64_t n);`.

Library Checker uses the same output definition with `N <= 10,000,000,000`. The local cap keeps a shared prefix table and memoized quotient states small across the nine standard ports and optional Mojo port.

## Algorithm and local coverage

The ports sieve totients through `B = 100,000` and store their modular prefix sums. For larger `n`, they use

`S(n) = n(n+1)/2 - sum_{k=2..n} S(floor(n/k)) (mod 998244353)`.

They group adjacent `k` values that share the same quotient and memoize the larger `S` values. This avoids building a totient table through the full input limit.

The local [`problem72`](../../p/problem72/README.md) package sums a totient table through `N <= 1,000,000`, returning the exact sum over `2..N`. It is closely related mathematically, but uses a direct table-prefix scan, while this package targets a much larger bound with quotient-block recursion and modular results. The scalar [`euler_totient`](../../e/euler_totient/README.md) and [`totients_linear_sieve`](../../t/totients_linear_sieve/README.md) packages return an individual totient or a sequence, respectively.

The [official task](https://github.com/yosupo06/library-checker-problems/blob/master/number_theory/sum_of_totient_function/task.md) specifies the modular summatory function; its [parameters](https://github.com/yosupo06/library-checker-problems/blob/master/number_theory/sum_of_totient_function/info.toml) set `N_MAX` to `10^10`. The local Python oracle is [`benchmarks/sum_of_totient_function_oracle.py`](../../sum_of_totient_function_oracle.py).

[`workload.json`](workload.json) covers small sums, the previous local prefix-sieve limit, a larger quotient-recursion case, and invalid bounds.

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/s/sum_of_totient_function.c`](../../../c/s/sum_of_totient_function.c) |
| C3 | [`c3/s/sum_of_totient_function.c3`](../../../c3/s/sum_of_totient_function.c3) |
| C++ | [`cpp/s/sum_of_totient_function.cpp`](../../../cpp/s/sum_of_totient_function.cpp) |
| Elisa | [`elisa/s/sum_of_totient_function.elisa`](../../../elisa/s/sum_of_totient_function.elisa) |
| Nim | [`nim/s/sum_of_totient_function.nim`](../../../nim/s/sum_of_totient_function.nim) |
| Odin | [`odin/s/sum_of_totient_function.odin`](../../../odin/s/sum_of_totient_function.odin) |
| Rust | [`rust/s/sum_of_totient_function.rs`](../../../rust/s/sum_of_totient_function.rs) |
| V | [`v/s/sum_of_totient_function.v`](../../../v/s/sum_of_totient_function.v) |
| Zig | [`zig/s/sum_of_totient_function.zig`](../../../zig/s/sum_of_totient_function.zig) |
| Mojo | [`mojo/s/sum_of_totient_function.mojo`](../../../mojo/s/sum_of_totient_function.mojo) |
