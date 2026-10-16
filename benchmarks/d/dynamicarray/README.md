# Go Dynamic Array Operation Trace

This benchmark models the pinned Go `DynamicArray` as a bounded stateful operation stream. It is distinct from [`dynamic_array`](../dynamic_array/README.md): that benchmark covers the shared append/update/get/size subset, while this one includes Go’s initial capacity of 10, stable removal, explicit capacity observations, and empty-state queries.

## Contract

- Input is `[operation_count, operation_records...]`, with at most 128 operations and 64 stored elements.
- A zero-value array begins with capacity 0. Its first append allocates capacity 10; capacity doubles on a later append when size equals capacity. Removal shifts following values left and does not shrink capacity.
- Opcodes: `0 [0,value]` append; `1 [1,index,value]` update an existing index; `2 [2,index]` get; `3 [3,index]` remove; `4 [4]` query size; `5 [5]` query capacity; `6 [6]` query empty (`1` when empty, otherwise `0`).
- The little-endian signed 64-bit output is `[query_count, query_results..., final_size, final_capacity, final_values...]`. Invalid traces return `-1`; insufficient output space returns `-2` without writing output.
- Values are signed 64-bit integers. Get, update, and remove accept only existing indices.

The pinned Go tests construct `DynamicArray{}`, so the starting capacity is 0. `Add` calls `NewCapacity` when size equals capacity; `NewCapacity` allocates capacity 10 from zero, then doubles on later growth. The benchmark models this automatic growth and reports capacity, but omits direct calls to the exported `NewCapacity` helper. `Put`, `Get`, and `Remove` reject indices outside the current elements. Removal copies the suffix left and decrements size without shrinking the backing capacity. `IsEmpty` checks size, and `GetData` exposes the populated prefix. The benchmark returns that populated prefix in its final snapshot. Allocation and Go interface values are represented by bounded integer buffers so the operation behavior remains deterministic across the nine compiled ports.

Pinned source: [TheAlgorithms/Go `structure/dynamicarray/dynamicarray.go`](https://github.com/TheAlgorithms/Go/blob/5ba447ec5ff3d1213de65b92e726ee74c5d5cc19/structure/dynamicarray/dynamicarray.go).

[`workload.json`](workload.json) exercises the capacity-10/20/40/80 growth boundaries, stable removals, empty queries, signed values, malformed traces, full size, and insufficient output capacity. The independent oracle is [`benchmarks/dynamicarray_oracle.py`](../../dynamicarray_oracle.py); [`benchmarks/verify_i64_array_bytes_output.py`](../../verify_i64_array_bytes_output.py) verifies all nine ports.

```sh
python3 benchmarks/verify_i64_array_bytes_output.py --algorithm dynamicarray
```
