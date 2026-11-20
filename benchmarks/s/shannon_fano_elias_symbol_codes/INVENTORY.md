# Static inventory

- Algorithm: `shannon_fano_elias_symbol_codes`
- ABI: `i64_array_bytes_output`
- Contract: up to 8 ordered symbols; positive weights at most 15 and total at
  most 120; 9 valid/10 parseable i64 words; 17 output bytes; 1,024 workspace
  bytes.
- Primary reference: integer cumulative-midpoint formula.
- Independent reference: exact rational binary-bit expansion.
- Fixtures: 14 package-local cases, including maximum frame/output, one-byte-
  short capacity, malformed frame, and null input/output.
- Sources: NIST DADS Shannon–Fano discovery entry and Gilbert–Moore 1959 paper;
  algorithm descriptions only.
- Suite/catalog integration: pending root.
- No programs, scripts, tests, helpers/checkers, builds, compilers, profilers,
  or benchmarks were run.
