# Package inventory

- Algorithm: `fornberg_finite_difference_weights`
- ABI: `i64_array_bytes_output`
- Profile: Fornberg's ordered-node derivative-weight recurrence over
  `F_998244353`; `n=1..8`, `m=0..min(3,n-1)`.
- Maximum input: 11 valid words, 12 parseable words.
- Maximum output: 72 little-endian bytes for `[n,weights...]`.
- Native workspace cap: 512 bytes.
- References: primary triangular recurrence and independent moment-system
  Gauss-Jordan solve.
- Source: Fornberg 1988, DOI `10.1090/S0025-5718-1988-0935077-0`; see
  [`RIGHTS.md`](RIGHTS.md) for rights and clean-room notes.
- Duplicate disposition: distinct from barycentric scalar evaluation and
  polynomial-representation construction/evaluation; see [`README.md`](README.md).
- Suite/catalog integration: shared byte-output runner and verifier registered.

All ten implementation paths are listed in `INVENTORY.json` and the README.
