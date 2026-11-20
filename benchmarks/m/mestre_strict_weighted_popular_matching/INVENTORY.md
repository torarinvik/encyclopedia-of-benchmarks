# Static package inventory

Algorithm: `mestre_strict_weighted_popular_matching`  
ABI: `i64_array_scalar`  
Source profile: Mestre, arXiv:0707.0546v1, strict preference lists,
Section 2/Figure 2, with the applicant-complete reduced-graph test described
by Abraham et al., Section 2.2.

## Bounded contract

- Applicants `A`: 1 through 4.
- Real jobs `J`: 1 through 5.
- Positive vote weights: 1 through 1000.
- Each applicant lists 1 through `J` distinct jobs in strict preference order.
- Input words: `[A,J,weights[A],lengths[A],rows...]`; maximum valid length 30,
  parseable invalid length 31.
- Output: 1 for existence, 0 for nonexistence, and -1 for invalid input.
- Workspace accounting: 4096 bytes.

## References and package artifacts

- `primary_oracle.py`: descending weight categories, promotion labels,
  category pruning, and augmenting-path completion.
- `independent_oracle.py`: feasible assignment enumeration and direct weighted
  vote comparison.
- `workload.json`: bounded deterministic fixtures, including a cascading
  promotion-label rejection and framing errors.
- `verify_workload.py`: static metadata and oracle-agreement review function.
- `check_inventory.py`: static package and ten-port inventory function.
- `README.md` and `RIGHTS.md`: profile distinction, source provenance, and
  rights notes.
- Shared `i64_array_scalar` runner and verifier registration is present; no
  executable checks have been run.

## Ports

| Language | Path |
|---|---|
| C | `c/m/mestre_strict_weighted_popular_matching.c` |
| C3 | `c3/m/mestre_strict_weighted_popular_matching.c3` |
| C++ | `cpp/m/mestre_strict_weighted_popular_matching.cpp` |
| Elisa | `elisa/m/mestre_strict_weighted_popular_matching.elisa` |
| Mojo | `mojo/m/mestre_strict_weighted_popular_matching.mojo` |
| Nim | `nim/m/mestre_strict_weighted_popular_matching.nim` |
| Odin | `odin/m/mestre_strict_weighted_popular_matching.odin` |
| Rust | `rust/m/mestre_strict_weighted_popular_matching.rs` |
| V | `v/m/mestre_strict_weighted_popular_matching.v` |
| Zig | `zig/m/mestre_strict_weighted_popular_matching.zig` |

The inventory is based on static source presence only. No executable check was
run.
