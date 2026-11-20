# Package inventory

- Algorithm: `order_preserving_huffman_greedy_trace`
- ABI: `i64_array_bytes_output`
- Bounds: 2–8 symbols, weights 1–15, 9 valid / 10 parseable words, 80 output bytes, 2,048 workspace bytes.
- Language ports: C, C3, C++, Elisa, Mojo, Nim, Odin, Rust, V, Zig.
- References: tree-node primary and active-interval/depth-vector independent model.
- Fixed workload: thirteen cases, including tie behavior, maximum valid/parseable frames, maximum output, and one-byte-short capacity.
- Shared suite/catalog integration: registered in `i64_array_bytes_output`.
- Static checks: `check_inventory.py` and `verify_workload.py` are written and have not been run.
