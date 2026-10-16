# Cyclic Linked List

This benchmark ports the pinned Go circular doubly linked list and its operations. The bounded trace covers append, rotation, deletion, traversal, destruction, and the file's Josephus routine. The implementation uses ordinary integer indices and fixed arrays to represent the circular next/previous links, so it is portable across the target languages.

## Contract

- Input is `[operation_count, (opcode, argument)...]`, with 0 through 64 operations. Opcodes are `0=Add(value)`, `1=Rotate(places)`, `2=Delete()`, `3=Walk()`, `4=JosephusProblem(k)`, and `5=Destroy()`.
- Added values are signed 32-bit integers. Rotation and Josephus steps range from -1,000,000 through 1,000,000. Delete, Walk, and Destroy take argument 0. JosephusProblem requires a nonempty list.
- Output is `[query_count, (operation_index, opcode, value_count, values...)..., final_size, final_values...]`, encoded as little-endian signed 64-bit values. Delete records 0 or 1; Walk records the traversal order; JosephusProblem records its winner and empties the list, matching the Go method's final Destroy call.
- The Go Josephus routine rotates by `k`, deletes the head, rotates by `-1`, repeats until one value remains, then destroys the list. This rotation convention is retained in the operation trace.
- The function returns the output byte count, `-1` for malformed traces or invalid operations, and `-2` for insufficient output capacity.

## Build and verify

```sh
python3 benchmarks/build_abi.py --family i64_array_bytes_output --algorithm cyclic --language cpp --with-checker
python3 benchmarks/run_i64_array_bytes_output.py --build-manifest build/i64_array_bytes_output/c/cyclic/cpp/build.json
```

## Pinned source

- Go [`cyclic.go`](https://github.com/TheAlgorithms/Go/blob/5ba447ec5ff3d1213de65b92e726ee74c5d5cc19/structure/linkedlist/cyclic.go)
