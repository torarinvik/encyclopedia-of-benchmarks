# Static inventory

Package: `cactus_graph_recognition`  
ABI: `i64_array_scalar`  
Exported symbol: `cactus_graph_recognition`  
Input: simple undirected `[N,M,(u,v)*M]`, `1<=N<=32`, `0<=M<=128`.  
Maximum valid/parseable input lengths: 258/259 words.  
Result: packed `4*C+2*V+E`, with `C<=42`; `-1` means invalid input.  
Workspace metadata: 8192 bytes.  
Primary: iterative DFS fundamental-cycle edge ownership and cycle-vertex counts.  
Independent: Tarjan biconnected edge blocks and simple-cycle classification.  
Ports: C, C3, C++, Elisa, Mojo, Nim, Odin, Rust, V, Zig.  
Suite wiring: `benchmarks/run_i64_array_scalar.py` and
`benchmarks/verify_i64_array_scalar.py`; exhaustive verifier comparison covers
every simple graph through five vertices plus malformed framing cases.

This inventory is static. The package verifier, tests, executables, and
compilers have not been run.
