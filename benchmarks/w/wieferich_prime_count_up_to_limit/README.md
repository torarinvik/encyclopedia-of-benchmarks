# Wieferich prime count up to a limit

This benchmark counts odd primes `p` at or below an inclusive limit `N` that satisfy

`2^(p-1) ≡ 1 (mod p^2)`.

## Contract

- ABI: `i64_array_scalar`; exported symbol: `wieferich_prime_count_up_to_limit`.
- Input is exactly `[N]`, with `2<=N<=5000`. The parser accepts at most two words so trailing data is rejected. Null, empty, malformed, or out-of-domain input returns `-1`.
- Count each odd prime once if its square divides `2^(p-1)-1`; the bound is inclusive.
- The primary sieves primes through `N`, then evaluates the congruence by binary modular exponentiation modulo `p^2`. The independent reference trial-divides each candidate for primality and applies `p-1` sequential modular doublings.
- At this cap, `p^2<=25,000,000` and the primary's largest multiplication is less than `(p^2)^2<=625,000,000,000,000`, below `INT64_MAX`. The independent reference multiplies a residue by two, below 50,000,000. Every port uses signed 64-bit intermediate values safely.
- The primary sieve stores `N+1<=5,001` one-byte flags. Its declared workspace cap is 8,192 bytes, including the fixed sieve and scalar state.
- The primary takes `O(N log log N + π(N) log N)` time. The independent method takes `O(N sqrt(N)+N^2)` time, with at most 25,000,000 trial and modular steps under this bound, and constant scalar workspace.

The result counts primes with a p-squared Fermat congruence. It differs from [`fermat_prime_checker`](../../f/fermat_prime_checker/README.md), which runs a seeded probable-prime test on one supplied value modulo that value; from [`multiplicative_order`](../../m/multiplicative_order/README.md), which returns the order of a supplied unit modulo one modulus; and from [`mersenne_primes`](../../m/mersenne_primes/README.md), which applies Lucas–Lehmer to `2^n-1`.

## Sources and provenance

Richard Crandall, Karl Dilcher, and Carl Pomerance define Wieferich primes by this congruence and report the known base-2 examples 1093 and 3511 in “A Search for Wieferich and Wilson Primes,” *Mathematics of Computation* 66(217) (1997), 433–449 ([primary article PDF](https://www.reed.edu/physics/faculty/crandall/papers/S0025-5718-97-00791-6.pdf)). The [RosettaCodeData popular-tasks index](https://raw.githubusercontent.com/acmeism/RosettaCodeData/main/popular-tasks) supplied the title discovery only. No task text, code, examples, tests, or fixtures are copied; the profile, ports, references, and workload are clean-room work.

## Language ports

| Language | Source |
| --- | --- |
| C | [`c/w/wieferich_prime_count_up_to_limit.c`](../../../c/w/wieferich_prime_count_up_to_limit.c) |
| C3 | [`c3/w/wieferich_prime_count_up_to_limit.c3`](../../../c3/w/wieferich_prime_count_up_to_limit.c3) |
| C++ | [`cpp/w/wieferich_prime_count_up_to_limit.cpp`](../../../cpp/w/wieferich_prime_count_up_to_limit.cpp) |
| Elisa | [`elisa/w/wieferich_prime_count_up_to_limit.elisa`](../../../elisa/w/wieferich_prime_count_up_to_limit.elisa) |
| Mojo | [`mojo/w/wieferich_prime_count_up_to_limit.mojo`](../../../mojo/w/wieferich_prime_count_up_to_limit.mojo) |
| Nim | [`nim/w/wieferich_prime_count_up_to_limit.nim`](../../../nim/w/wieferich_prime_count_up_to_limit.nim) |
| Odin | [`odin/w/wieferich_prime_count_up_to_limit.odin`](../../../odin/w/wieferich_prime_count_up_to_limit.odin) |
| Rust | [`rust/w/wieferich_prime_count_up_to_limit.rs`](../../../rust/w/wieferich_prime_count_up_to_limit.rs) |
| V | [`v/w/wieferich_prime_count_up_to_limit.v`](../../../v/w/wieferich_prime_count_up_to_limit.v) |
| Zig | [`zig/w/wieferich_prime_count_up_to_limit.zig`](../../../zig/w/wieferich_prime_count_up_to_limit.zig) |

The primary and independent Python references use distinct sieve/binary-power and trial-division/linear-power methods. `verify_workload.py` expresses the oracle-to-fixture review, and `check_inventory.py` pins source paths and package metadata. No executable checks were run.

The ten language ports are registered in the shared `i64_array_scalar`
runner and verifier.
