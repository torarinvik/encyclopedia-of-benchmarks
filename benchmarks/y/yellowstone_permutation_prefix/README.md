# Yellowstone permutation prefix

This profile returns one term of the Yellowstone permutation, a greedy sequence built from the two preceding terms. It is not random: the candidate order is fixed and the selection rule is deterministic.

## Contract

- ABI: `i64_array_scalar`; symbol: `yellowstone_permutation_prefix`.
- Input is exactly `[N,candidate_cap]`, with `1<=N<=64` and `3<=candidate_cap<=256`. The parseable frame cap is three words so an extra trailing word is rejected.
- Indexing is one-based with `a(1)=1`, `a(2)=2`, and `a(3)=3`; requests for these base terms return directly.
- For each later term, scan positive candidates from 1 through `candidate_cap`, inclusive. Skip any candidate already in the generated prefix. Select the first candidate `x` for which `gcd(x,a(n-2))>1` and `gcd(x,a(n-1))=1`.
- If any requested step has no candidate within the inclusive cap, the whole request is invalid and returns `-1`. The cap limits the search; it does not claim every cap will produce the requested term.
- The primary uses Euclid GCD and a used-value table. The independent Python reference factors candidates by trial division, intersects prime-factor sets for the gcd predicates, and checks membership with a prefix scan.
- Workspace accounting is 512 bytes for 64 i64 prefix entries plus 257 bytes for the used-value table, or 769 bytes for the fixed arrays; scalar loop state fits within the 1,024-byte cap. Each request performs at most `N*candidate_cap` candidate checks.

The bounded workload includes base terms, generated terms, a published high-index term, a cap-exhaustion failure at the first step, a failure after partial prefix growth, malformed frames, and i64 boundary values. `a(64)=93` is taken from the article's published prefix table.

This method differs from [`ekg_sequence`](../../e/ekg_sequence/README.md), whose choice depends only on sharing a factor with the immediately previous term. It is also distinct from the greedy pair-sum condition of [`mian_chowla_sequence`](../../m/mian_chowla_sequence/README.md), the last-occurrence recurrence of [`van_ecks_sequence`](../../v/van_ecks_sequence/README.md), and the complementary construction in [`hofstadter_figure_figure_sequences`](../../h/hofstadter_figure_figure_sequences/README.md).

## Source and provenance

The recurrence is defined by Applegate, Havermann, Selcoe, Shevelev, Sloane, and Zumkeller, “The Yellowstone Permutation,” *Journal of Integer Sequences* 18 (2015), Article 15.6.7 ([paper](https://www.maths.tcd.ie/EMIS/journals/JIS/VOL18/Sloane/sloane9.pdf)). [OEIS A098550](https://oeis.org/A098550) indexes the same sequence. The [RosettaCodeData popular-tasks index](https://raw.githubusercontent.com/acmeism/RosettaCodeData/main/popular-tasks) was used only to discover the title. No Rosetta task text, code, or fixtures were used.

## Language ports

| Language | Source |
| --- | --- |
| C | [`c/y/yellowstone_permutation_prefix.c`](../../../c/y/yellowstone_permutation_prefix.c) |
| C3 | [`c3/y/yellowstone_permutation_prefix.c3`](../../../c3/y/yellowstone_permutation_prefix.c3) |
| C++ | [`cpp/y/yellowstone_permutation_prefix.cpp`](../../../cpp/y/yellowstone_permutation_prefix.cpp) |
| Elisa | [`elisa/y/yellowstone_permutation_prefix.elisa`](../../../elisa/y/yellowstone_permutation_prefix.elisa) |
| Mojo | [`mojo/y/yellowstone_permutation_prefix.mojo`](../../../mojo/y/yellowstone_permutation_prefix.mojo) |
| Nim | [`nim/y/yellowstone_permutation_prefix.nim`](../../../nim/y/yellowstone_permutation_prefix.nim) |
| Odin | [`odin/y/yellowstone_permutation_prefix.odin`](../../../odin/y/yellowstone_permutation_prefix.odin) |
| Rust | [`rust/y/yellowstone_permutation_prefix.rs`](../../../rust/y/yellowstone_permutation_prefix.rs) |
| V | [`v/y/yellowstone_permutation_prefix.v`](../../../v/y/yellowstone_permutation_prefix.v) |
| Zig | [`zig/y/yellowstone_permutation_prefix.zig`](../../../zig/y/yellowstone_permutation_prefix.zig) |

`workload.json` is cross-referenced by `primary_oracle.py` and `independent_oracle.py` through `verify_workload.py`. `check_inventory.py` statically pins the ten ports, ABI symbol, null guards, and documentation links. The scalar runner and verifier plus README and CATALOG entries are integrated; no static helper or benchmark was run.
