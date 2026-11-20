# Static package inventory

- ABI: `i64_array_scalar`; exported symbol: `smallest_number_with_n_divisors`.
- Input: exactly `[d, limit]`, `1<=d<=63`, `1<=limit<=1,000,000`.
- Output: least `N<=limit` with exactly `d` positive divisors; `0` for a valid
  bounded miss and `-1` for malformed or out-of-profile input.
- Primary reference: enumerate nonincreasing multiplicative factorizations of
  `d`, assigning each factor minus one as an exponent of the next prime.
- Independent reference: divisor-count sieve through the supplied inclusive
  limit, then a left-to-right search.
- Ports: C, C3, C++, Elisa, Mojo, Nim, Odin, Rust, V, Zig.
- Workload and source inventory: `workload.json` and `check_inventory.py`.
- Provenance: `RIGHTS.md`; mathematical references are listed in `README.md`.

The inverse search is distinct from local forward divisor-count profiles:
`number_of_positive_divisors` factors a supplied number, while
`divisors_count_sequence` scans divisors to emit a sequence. This package
searches the constrained multiplicative partitions of a target count.
