# Measured finger-tree sequence

This bounded benchmark exercises a persistent measured 2–3 finger tree. Each tree is represented by `Empty`, `Single`, or `Deep(prefix,middle,suffix)`; digits contain one to four items and middle items are `Node2`/`Node3` groups. The monoidal annotation is `(element_count, value_sum)`. Implementations use immutable indexed arenas so earlier root IDs remain usable.

## Contract

The `i64_array_bytes_output` symbol is `measured_finger_tree_sequence`. Input is `[n0,initial_values...,Q,(tag,a,b,x,y)*Q]`. `0<=n0<=32`, `1<=Q<=32`, values are in `[0,1000000]`, and every created sequence is at most 64 values with sum at most 64000000. Root 0 is the initial sequence. Roots are persistent and IDs are assigned in creation order; each split creates two roots.

Each five-word operation is:

| Tag | Arguments `(a,b,x,y)` | Operation |
|---:|---|---|
| 0 | `(root,-1,value,-1)` | Push left |
| 1 | `(root,-1,value,-1)` | Push right |
| 2 | `(root,-1,-1,-1)` | Pop left |
| 3 | `(root,-1,-1,-1)` | Pop right |
| 4 | `(left_root,right_root,-1,-1)` | Concatenate |
| 5 | `(root,-1,index,-1)` | Split before the indexed element |
| 6 | `(root,-1,threshold,-1)` | Split after the first prefix whose sum reaches the positive threshold |

An absent sum threshold splits at the sequence end and reports auxiliary value `-1`. Empty pops, bad root IDs, non-sentinel unused fields, invalid ranges, overlong sequences, and overlarge sums return `-1`. Malformed input is checked before output capacity. A valid null or short output returns `-2` without writes.

Each operation emits seven signed 64-bit little-endian words: `(left_root,left_length,left_sum,right_root,right_length,right_sum,aux)`. A single-result operation uses `-1` for all three right-result fields. `aux` is the popped value for pop, the split index for either split when found, and `-1` otherwise. Maximum input length is 194 words (195 parseable); output is at most 1792 bytes. The fixed workspace allowance is 1 MiB, including a 16384-object immutable node arena, root metadata, and staged output.

The primary reference uses a plain list per persistent version; the independent reference stores tuple versions and separately interprets the operation stream. The bounded strict-language ports implement the same immutable finger-tree representation. They preserve prior roots; this package does not claim a measured asymptotic timing result or an amortized end-operation bound for eager arena evaluation.

See [`workload.json`](workload.json), [`oracle.py`](oracle.py), [`independent_oracle.py`](independent_oracle.py), [`verify_workload.py`](verify_workload.py), and [`RIGHTS.md`](RIGHTS.md).

## Ports

| Language | Source |
|---|---|
| C | [`c/m/measured_finger_tree_sequence.c`](../../../c/m/measured_finger_tree_sequence.c) |
| C3 | [`c3/m/measured_finger_tree_sequence.c3`](../../../c3/m/measured_finger_tree_sequence.c3) |
| C++ | [`cpp/m/measured_finger_tree_sequence.cpp`](../../../cpp/m/measured_finger_tree_sequence.cpp) |
| Elisa | [`elisa/m/measured_finger_tree_sequence.elisa`](../../../elisa/m/measured_finger_tree_sequence.elisa) |
| Mojo | [`mojo/m/measured_finger_tree_sequence.mojo`](../../../mojo/m/measured_finger_tree_sequence.mojo) |
| Nim | [`nim/m/measured_finger_tree_sequence.nim`](../../../nim/m/measured_finger_tree_sequence.nim) |
| Odin | [`odin/m/measured_finger_tree_sequence.odin`](../../../odin/m/measured_finger_tree_sequence.odin) |
| Rust | [`rust/m/measured_finger_tree_sequence.rs`](../../../rust/m/measured_finger_tree_sequence.rs) |
| V | [`v/m/measured_finger_tree_sequence.v`](../../../v/m/measured_finger_tree_sequence.v) |
| Zig | [`zig/m/measured_finger_tree_sequence.zig`](../../../zig/m/measured_finger_tree_sequence.zig) |
