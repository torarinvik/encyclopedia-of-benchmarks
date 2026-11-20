# Package inventory

Algorithm: `hashbelt_aging_hash_table`  
ABI: `i64_array_bytes_output`  
Input: at most 64 triples and 193 valid signed-i64 words  
Output: one little-endian signed-i64 result per operation, at most 512 bytes  
Workspace: 4,096 bytes

The source set is C, C3, C++, Elisa, Mojo, Nim, Odin, Rust, V, and Zig. The
package records the DADS and Grosso provenance, bounded contract, workload,
two independent references, static inventory checker, and workload verifier.
Shared suite and catalog registration are owned by the root agent.
