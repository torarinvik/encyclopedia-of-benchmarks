# Prefix-Substring LCS

For two lowercase strings `S` and `T`, answer batched queries for the LCS
length between a prefix `S[0:a)` and a substring `T[b:c)`. The package uses the
semi-local LCS boundary recurrence to prepare all prefix states, then sweeps
each state by the query's left endpoint with a Fenwick tree.

## Contract

The exported symbol is `prefix_substring_lcs` in the
`i64_array_bytes_output` ABI family. The signed 64-bit input is packed as
`[|S|, |T|, Q, S character codes..., T character codes..., (a,b,c)...]`.
Characters are lowercase ASCII values 97 through 122. The bounded profile
requires `1<=|S|,|T|<=32`, `1<=Q<=64`, `0<=a<=|S|`, and
`0<=b<=c<=|T|`. The packed input has at most 259 words.

Successful output contains one signed 64-bit little-endian LCS length per
query, in input order, for at most 512 bytes. A malformed or out-of-profile
input returns `-1`. A null output pointer or output capacity below `8*Q`
returns `-2`. Errors leave the output untouched. The workspace bound is
65,536 bytes.

## Algorithm

Let `H[i][j]` and `V[i][j]` be the horizontal and vertical semi-local LCS
boundary values. Initialize `H[0][j]=j` and `V[0][j]=0`. For each character
pair, let `u=H[i-1][j]` and `v=V[i][j-1]`. On a match set
`H[i][j]=v, V[i][j]=u`; otherwise set `H[i][j]=max(u,v), V[i][j]=min(u,v)`.
For a query `(a,b,c)`, the answer is the number of indices
`j in [b+1,c+1)` for which `H[a][j]<=b`.

Queries are grouped by `(a,b)`. For each prefix row `a`, bucket its `H[a][j]`
values by value and sweep `b` upward. Activate positions whose boundary value
is at most `b` in a Fenwick tree, then query the index interval
`[b+1,c+1)`. The preparation costs `O(|S||T|)` and the sweeps cost
`O((|S||T|+Q) log |T|)` time, with `O(|S||T|+Q)` bounded storage.

The primary oracle follows this semi-local recurrence and Fenwick sweep. The
independent verifier runs a fresh rolling-row LCS dynamic program for every
query. The workload includes repeated symbols, empty prefix/substring ranges,
malformed inputs, and output-capacity failures. See [`RIGHTS.md`](RIGHTS.md)
for clean-room provenance.

## Ports

| Language | Source |
|---|---|
| C | [`c/p/prefix_substring_lcs.c`](../../../c/p/prefix_substring_lcs.c) |
| C3 | [`c3/p/prefix_substring_lcs.c3`](../../../c3/p/prefix_substring_lcs.c3) |
| C++ | [`cpp/p/prefix_substring_lcs.cpp`](../../../cpp/p/prefix_substring_lcs.cpp) |
| Elisa | [`elisa/p/prefix_substring_lcs.elisa`](../../../elisa/p/prefix_substring_lcs.elisa) |
| Mojo | [`mojo/p/prefix_substring_lcs.mojo`](../../../mojo/p/prefix_substring_lcs.mojo) |
| Nim | [`nim/p/prefix_substring_lcs.nim`](../../../nim/p/prefix_substring_lcs.nim) |
| Odin | [`odin/p/prefix_substring_lcs.odin`](../../../odin/p/prefix_substring_lcs.odin) |
| Rust | [`rust/p/prefix_substring_lcs.rs`](../../../rust/p/prefix_substring_lcs.rs) |
| V | [`v/p/prefix_substring_lcs.v`](../../../v/p/prefix_substring_lcs.v) |
| Zig | [`zig/p/prefix_substring_lcs.zig`](../../../zig/p/prefix_substring_lcs.zig) |

[`workload.json`](workload.json) and the package-local
[`verify_workload.py`](verify_workload.py) record and statically check the
profile. The checker reads files and oracle fixtures only; it does not launch
the language ports.
