# Static inventory

Package: `monge_dag_fixed_edge_shortest_path`  
ABI: `i64_array_scalar`  
Exported symbol: `monge_dag_fixed_edge_shortest_path`  
Input: `[N,D, upper_triangle_costs]` for implicit vertices `0..N`, with
`1<=N<=32`, `1<=D<=N`, and nonnegative costs through one million.  
Maximum valid input length: 530 words; parseable bound: 531 words.  
Maximum valid scalar result: 32,000,000.  
Workspace metadata: 16384 bytes.  
Primary: monotone divide-and-conquer minima per exact-edge DP layer.  
Independent: direct scan over all prior vertices per layer.  
Monge promise: validated from all adjacent quadrangles fully inside the upper
triangle.  
Ports: C, C3, C++, Elisa, Mojo, Nim, Odin, Rust, V, Zig.  
Suite wiring: `i64_array_scalar` runner and verifier registered.

This inventory is static. No package verifier, test, executable, or compiler
has been run.
