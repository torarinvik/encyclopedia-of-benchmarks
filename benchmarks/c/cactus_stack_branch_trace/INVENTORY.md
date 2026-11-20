# Package inventory

- Algorithm: bounded cactus/saguaro stack branch trace
- ABI: `i64_array_bytes_output`
- Symbol: `cactus_stack_branch_trace`
- Native ports: C, C3, C++, Elisa, Mojo, Nim, Odin, Rust, V, Zig
- References: node-table primary; copied-vector independent model
- Input: at most 48 fixed-width operation triples (145 valid / 146 parseable words)
- Output: 16 bytes per operation, at most 768 bytes
- Workspace: at most 4,096 bytes
- Workload: branch attachment, notch query, blocked pop, push/pop around a
  notch, child-empty detachment, empty child, malformed operations, null and
  short output, maximum frame and maximum output
- Provenance: NIST DADS cactus stack and Hauck–Dent AFIPS 1968 paper
- Shared suite/catalog registration: integrated in `i64_array_bytes_output`
- Runtime validation: intentionally not run
