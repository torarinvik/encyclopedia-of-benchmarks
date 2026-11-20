# Package inventory

- Algorithm: `cyclotomic_polynomial_coefficients`
- ABI: `i64_array_bytes_output`
- Contract: input `[n]`, `1 <= n <= 32`; output `Phi_n` coefficients in
  ascending degree order as little-endian signed-i64 words.
- Maximum valid/parseable input lengths: 1/2 words.
- Maximum output: 248 bytes for `n=31`.
- Workspace allowance: 16,384 bytes, excluding caller buffers.
- Primary reference: recursive proper-divisor product followed by exact
  monic polynomial quotient.
- Independent reference: Ramanujan power sums and Newton identities.
- Workload: `workload.json`; metadata-only helpers are listed below.
- Rights and source provenance: [`RIGHTS.md`](RIGHTS.md).
- Duplicate disposition: not equivalent to the Möbius function, polynomial
  interpolation/evaluation, or formal-series operations; see [`README.md`](README.md).
- Shared runner/catalog integration: registered in `run_i64_array_bytes_output.py`, `verify_i64_array_bytes_output.py`, and the repository catalog.

The ten native source paths are listed in `INVENTORY.json` and `README.md`.
`check_inventory.py` performs static path/metadata checks, and
`verify_workload.py` compares fixtures against both references. Neither has
been executed.
