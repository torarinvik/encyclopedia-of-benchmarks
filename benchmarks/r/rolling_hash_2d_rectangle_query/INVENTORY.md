# Static inventory

Package: `rolling_hash_2d_rectangle_query`  
ABI: `i64_array_bytes_output`  
Exported symbol: `rolling_hash_2d_rectangle_query`  
Input: `[H,W,Q, grid(H*W), (r0,c0,r1,c1)*Q]`; dimensions at most 32, query
count at most 128, symbols 0–255, and half-open in-bounds rectangles.  
Maximum valid input: 1539 signed-i64 words; parser limit: 1540 words.  
Output: Q normalized rectangle hashes as little-endian i64, maximum 1024 bytes.  
Hash parameters: row base 31, column base 37, prime modulus 1,000,000,007.  
Workspace metadata: 16,384 bytes.  
Algorithm: row-wise polynomial prefixes extended along the row axis; query
normalization by four-corner inclusion/exclusion in O(1).  
Primary reference: 2D prefix hash. Independent reference: direct weighted-cell
sum for each query.  
Ports: C, C3, C++, Elisa, Mojo, Nim, Odin, Rust, V, Zig.  
Shared `i64_array_bytes_output` runner/verifier registration is present in
`benchmarks/run_i64_array_bytes_output.py` and
`benchmarks/verify_i64_array_bytes_output.py`; the root README, catalog, and
coverage ledger include this profile.

This inventory is static. No package checker, executable, compiler, or test has
been run.
