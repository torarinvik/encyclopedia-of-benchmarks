# Rodinia B+ tree point search

This package isolates the source's GPU `findK` operation over a deterministic, prebuilt B+ tree. The profile has one internal root and two linked-leaf slots represented as sorted record lists. The root separator is the smallest key in the right leaf. Tree construction, file parsing, CUDA setup, and random query generation are outside the measured operation.

## Contract

- ABI: `i64_array_scalar`; exported symbol: `rodinia_bplus_tree`.
- Input layout: `[left_count, right_count, query_count, (left_key, left_value)..., (right_key, right_value)..., query...]`.
- Each leaf contains 1–3 unique, strictly increasing keys. All left keys are less than all right keys. Keys and queries are in `[-1,000,000, 1,000,000]`; record values are in `[0, 1,000,000]`; query count is 1–16.
- For each query, route to the left leaf when it is below the separator, otherwise to the right leaf; scan that leaf for equality. A missing key contributes the source's initialized `-1` answer as zero after the documented `answer + 1` scalar projection.
- Return `sum((query_index + 1) * (record_value + 1))` for found keys. Invalid input returns `-1`.
- The bounded order is four: each leaf has at most `order - 1 = 3` keys. This profile executes one internal routing level and leaf lookup, including the separator equality case.

The independent Python oracle stores leaves as key/value tuples and performs route-then-scan lookup, while the nine ports use bounded fixed arrays. Workload cases cover left/right routing, equality at the separator, misses, and malformed key order.

## Pinned source and rights

- Source: [`cuda/b+tree/kernel/kernel_gpu_cuda.cu`](https://github.com/utcs-scea/rodinia/blob/f30e63663cfb114939a15c7ffc4ae112055ae6a8/cuda/b%2Btree/kernel/kernel_gpu_cuda.cu) and its host serialization in [`cuda/b+tree/main.c`](https://github.com/utcs-scea/rodinia/blob/f30e63663cfb114939a15c7ffc4ae112055ae6a8/cuda/b%2Btree/main.c), pinned at commit `f30e63663cfb114939a15c7ffc4ae112055ae6a8`.
- The B+ tree source credits Amittai Aviram; the CUDA conversion credits Jordan Fix and Andrew Wilkes; the portable conversion and later distribution changes credit Lukasz G. Szafaryn and Ke Wang. The full University of Virginia Rodinia redistribution notice and citation request are in [`LICENSE.txt`](LICENSE.txt).

## Ports and workload

Ports are in `c/b`, `c3/b`, `cpp/b`, `elisa/b`, `nim/b`, `odin/b`, `rust/b`, `v/b`, and `zig/b`. The independent oracle is [`benchmarks/rodinia_bplus_tree_oracle.py`](../../rodinia_bplus_tree_oracle.py); static cases are in [`workload.json`](workload.json).
