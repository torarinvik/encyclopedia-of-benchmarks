# Smarandache–Wellin prime-prefix scan

This benchmark constructs bounded base-10 concatenations of consecutive primes and retains the values that are prime. The measured kernel includes next-prime generation, incremental decimal concatenation, primality classification, and serialization of the selected prefix values.

## Contract

The exported `smarandache_wellin_prime_prefix_scan` function uses the `i64_array_bytes_output` ABI. Its input frame is `[count]`, where `count` is in `0..6`. For each prefix length `k=1..count`, the algorithm appends the decimal digits of the first `k` ordinary primes in increasing order and tests the resulting integer. Prime-valued prefixes are emitted in increasing `k` order, each as one signed-i64 little-endian word.

The first six concatenations are `2`, `23`, `235`, `2357`, `235711`, and `23571113`. Only the first, second, and fourth are prime, so the maximum result is three words (24 bytes). For the composite values, `235` is divisible by 5, `235711` is divisible by 7, and `23571113 = 23 × 29 × 35339`. The value 2357 is prime by trial division through its square root. All generated candidates are below `2^32`; the primary uses the deterministic Miller–Rabin base set `{2,7,61}`, which covers this range. Products of two residues below `2^32` fit in `u64`.

Malformed input, null input, or a frame other than exactly one count word returns `-1`. A null output pointer or a capacity below the exact result byte length returns `-2`; output is untouched on either error. A zero count produces an empty result and succeeds with a non-null output pointer even when capacity is zero. Input validation happens before the output check.

The primary reference streams candidate primes and applies small-prime screening followed by Miller–Rabin. The independent reference sieves the first six primes, builds each prefix using decimal-place scaling, then trial-divides each complete prefix through its square root. Their prime generation and primality procedures differ structurally.

## Sources and scope

The sequence is defined by OEIS [A019518](https://oeis.org/A019518); its prime-valued subsequence is OEIS [A069151](https://oeis.org/A069151). MathWorld describes the [Smarandache–Wellin numbers](https://mathworld.wolfram.com/Smarandache-WellinNumber.html) and [Smarandache–Wellin primes](https://mathworld.wolfram.com/Smarandache-WellinPrime.html). For the primality method bound, Forisek and Jančina, [“Fast Primality Testing for Integers That Fit into a Machine Word,” Theorem 3](https://ceur-ws.org/Vol-1326/020-Forisek.pdf), supplies the `{2,7,61}` bases for all values below 4,759,123,141.

The score-18 “Smarandache-Wellin-primes” entry in the pinned [RosettaCodeData popular-task index](https://github.com/acmeism/RosettaCodeData/blob/1d475861d7141ef2fafff293d9339f56e4b0f5db/popular-tasks) was used for discovery only. This package does not reuse task code, wording, examples, or tests. It is distinct from primorial generation, which multiplies primes, and pairwise prime-concatenation searches, which test concatenated pairs rather than prefixes of the consecutive-prime sequence.

The declared native workspace cap is 256 bytes, including three staged `u64` values, a 24-byte output staging area, bounded primality constants, and scalar state; caller-owned ABI buffers are excluded. The package is registered in the shared `i64_array_bytes_output` suite. Package helpers and programs remain unrun.

## Native ports

| Language | Source |
| --- | --- |
| C | [`c/s/smarandache_wellin_prime_prefix_scan.c`](../../../c/s/smarandache_wellin_prime_prefix_scan.c) |
| C3 | [`c3/s/smarandache_wellin_prime_prefix_scan.c3`](../../../c3/s/smarandache_wellin_prime_prefix_scan.c3) |
| C++ | [`cpp/s/smarandache_wellin_prime_prefix_scan.cpp`](../../../cpp/s/smarandache_wellin_prime_prefix_scan.cpp) |
| Elisa | [`elisa/s/smarandache_wellin_prime_prefix_scan.elisa`](../../../elisa/s/smarandache_wellin_prime_prefix_scan.elisa) |
| Mojo | [`mojo/s/smarandache_wellin_prime_prefix_scan.mojo`](../../../mojo/s/smarandache_wellin_prime_prefix_scan.mojo) |
| Nim | [`nim/s/smarandache_wellin_prime_prefix_scan.nim`](../../../nim/s/smarandache_wellin_prime_prefix_scan.nim) |
| Odin | [`odin/s/smarandache_wellin_prime_prefix_scan.odin`](../../../odin/s/smarandache_wellin_prime_prefix_scan.odin) |
| Rust | [`rust/s/smarandache_wellin_prime_prefix_scan.rs`](../../../rust/s/smarandache_wellin_prime_prefix_scan.rs) |
| V | [`v/s/smarandache_wellin_prime_prefix_scan.v`](../../../v/s/smarandache_wellin_prime_prefix_scan.v) |
| Zig | [`zig/s/smarandache_wellin_prime_prefix_scan.zig`](../../../zig/s/smarandache_wellin_prime_prefix_scan.zig) |

See [`workload.json`](workload.json), [`RIGHTS.md`](RIGHTS.md), and [`INVENTORY.md`](INVENTORY.md). `check_inventory.py` and `verify_workload.py` are static source helpers and are not invoked during this work.
