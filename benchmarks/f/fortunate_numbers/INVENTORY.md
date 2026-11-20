# Package inventory

- Algorithm: `fortunate_numbers`
- ABI: `i64_array_scalar`, input `[n]`, one-based `1<=n<=10`.
- Output: least bounded `m` with `P_n+m` prime, `m=2..64`; `-1` invalid and `-2` bounded-search exhaustion.
- Native workspace cap: 128 bytes.
- References: trial-division primary and segmented-sieve independent reference.
- Workload: `workload.json`, including the first ten OEIS A005235 terms.
- Ports: C, C3, C++, Elisa, Mojo, Nim, Odin, Rust, V, and Zig.
- Shared suite/catalog registration: integrated in the i64-array-scalar runner/verifier and repository catalog.
