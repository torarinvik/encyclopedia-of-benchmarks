# Keys-only IBLT set reconciliation

This package replays the set-difference peeling core of an invertible Bloom
lookup table (IBLT). It builds a signed difference table by adding keys from
the first set and subtracting keys from the second, then recovers isolated
keys from cells whose signed count is one.

## Bounded contract

Input is `[a_count,b_count,A_keys...,B_keys...]`. Each set has at most eight
keys from `0..63`, sorted strictly increasingly. The sets may overlap. The
fixed table has three subtables of 16 cells each. Key `x` uses the distinct
locations:

- `h0(x) = x mod 16`
- `h1(x) = 16 + ((3*x + 5) mod 16)`
- `h2(x) = 32 + ((5*x + 9) mod 16)`

Each cell stores signed `count`, `key_sum`, and `check_sum`. Adding a key
contributes `(1,x,g(x))`; subtracting contributes `(-1,-x,-g(x))`, where
`g(x)=x*x+3*x+7`. Repeatedly choose the lowest-index cell with count `+1` or
`-1`, a key in `0..63` after applying the sign, and a matching signed
checksum. Emit that key on the first-set-only or second-set-only side, then
undo its signed contribution at all three locations. Stop when no pure cell
remains or after 16 peels. Output is `[complete,a_only_count,b_only_count,
a_only_keys...,b_only_keys...]`, with each field an eight-byte little-endian
i64; keys on each side are sorted before serialization. `complete` is one
only when all cells are zero and no repeated candidate was encountered. A
nonempty residual core produces a valid incomplete result containing the keys
already peeled.

The profile uses fixed deterministic placements and checksum arithmetic to
make traces repeatable. It makes no probability guarantee for these chosen
functions. Common keys cancel only as identical set members; duplicate keys
within either input set are invalid. The largest input is 18 words (19 words
at the parser boundary), the largest output is 152 bytes, and workspace is
capped at 2,048 bytes. Invalid input returns `-1`; after processing a valid
trace, null output or insufficient capacity returns `-2` without writes.

The primary reference mutates the table and rescans cells in ascending order.
The independent reference rebuilds the residual table from the original
signed terms and recorded peel corrections before each scan; it does not
mutate a cell table in place.

## Duplicate comparison

This differs from [`bloom_filter`](../../b/bloom_filter/README.md), which
answers approximate membership queries, and
[`xor_filter_peeling`](../../x/xor_filter_peeling/README.md), which peels a
three-way graph to assign fingerprints for static membership queries. The
IBLT emits the signed set difference between two key sets.

## Provenance

The core follows the IBLT architecture and listing procedure in Goodrich and
Mitzenmacher, “Invertible Bloom Lookup Tables,” *Allerton* (2011; v3, 2015),
especially §§2.2–2.4 and §3. The NIST DADS [IBLT entry](https://xlinux.nist.gov/dads/HTML/invertibleBloomTable.html)
links to that paper. See [RIGHTS.md](RIGHTS.md) for provenance and reuse
details.

## Language ports

| Language | Source |
|---|---|
| C | [`c/i/invertible_bloom_lookup_table_reconciliation.c`](../../../c/i/invertible_bloom_lookup_table_reconciliation.c) |
| C3 | [`c3/i/invertible_bloom_lookup_table_reconciliation.c3`](../../../c3/i/invertible_bloom_lookup_table_reconciliation.c3) |
| C++ | [`cpp/i/invertible_bloom_lookup_table_reconciliation.cpp`](../../../cpp/i/invertible_bloom_lookup_table_reconciliation.cpp) |
| Elisa | [`elisa/i/invertible_bloom_lookup_table_reconciliation.elisa`](../../../elisa/i/invertible_bloom_lookup_table_reconciliation.elisa) |
| Mojo | [`mojo/i/invertible_bloom_lookup_table_reconciliation.mojo`](../../../mojo/i/invertible_bloom_lookup_table_reconciliation.mojo) |
| Nim | [`nim/i/invertible_bloom_lookup_table_reconciliation.nim`](../../../nim/i/invertible_bloom_lookup_table_reconciliation.nim) |
| Odin | [`odin/i/invertible_bloom_lookup_table_reconciliation.odin`](../../../odin/i/invertible_bloom_lookup_table_reconciliation.odin) |
| Rust | [`rust/i/invertible_bloom_lookup_table_reconciliation.rs`](../../../rust/i/invertible_bloom_lookup_table_reconciliation.rs) |
| V | [`v/i/invertible_bloom_lookup_table_reconciliation.v`](../../../v/i/invertible_bloom_lookup_table_reconciliation.v) |
| Zig | [`zig/i/invertible_bloom_lookup_table_reconciliation.zig`](../../../zig/i/invertible_bloom_lookup_table_reconciliation.zig) |

Package-local workload, references, rights, and static inventory accompany
the ports. The shared byte-output runner and verifier plus README and CATALOG
registration are integrated; no programs or checks were run.
