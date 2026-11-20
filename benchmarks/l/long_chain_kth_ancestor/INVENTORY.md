# Static inventory

Algorithm symbol: `long_chain_kth_ancestor`  
ABI: `i64_array_bytes_output`  
Input: `[N,Q,parent[1..N-1],(vertex,k)*Q]`, `1<=N<=64`, `1<=Q<=32`.  
Output: `8*Q` little-endian i64 answers; `-1` means the requested ancestor is
above root.  
Malformed input returns `-1`; null/short output returns `-2` without writes.  
Output cap: 256 bytes. Workspace cap: 16,384 bytes.

The six binary-lifting rows use 3,072 bytes. Nine fixed 64-word arrays use
4,608 bytes in the widest ports; the remaining 8,704 bytes cover scalar
locals, alignment, and ABI bookkeeping.

| Language | Source |
|---|---|
| C | `c/l/long_chain_kth_ancestor.c` |
| C3 | `c3/l/long_chain_kth_ancestor.c3` |
| C++ | `cpp/l/long_chain_kth_ancestor.cpp` |
| Elisa | `elisa/l/long_chain_kth_ancestor.elisa` |
| Mojo | `mojo/l/long_chain_kth_ancestor.mojo` |
| Nim | `nim/l/long_chain_kth_ancestor.nim` |
| Odin | `odin/l/long_chain_kth_ancestor.odin` |
| Rust | `rust/l/long_chain_kth_ancestor.rs` |
| V | `v/l/long_chain_kth_ancestor.v` |
| Zig | `zig/l/long_chain_kth_ancestor.zig` |

Primary reference: `primary_oracle.py`, highest-power binary lift plus
long-chain head/offset lookup. Independent reference: `independent_oracle.py`,
direct parent stepping. Workload and expected bytes are pinned in
`workload.json`; static inventory entry point is `check_inventory.py`.
