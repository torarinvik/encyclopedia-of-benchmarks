# Reverse linked-list nodes in groups

Reverse complete groups of `k` nodes in a singly linked list. The pinned Java implementation counts the nodes, reverses one group at a time, and leaves a final group shorter than `k` unchanged. The benchmark represents the list as its payload array, so node relinking is observed through the resulting payload order.

## Contract

The `i32_array_bytes_output` ABI receives a direct signed-32-bit array `[k, values...]`; the first element is the group size and all following elements are list payloads. The list length is 0 through 256, every payload is any signed 32-bit integer, and `k` is 1 through 256. If `k` exceeds the list length, the list is unchanged. A null input pointer, invalid `k`, or an array longer than 257 valid cells returns `-1`. The maximum parseable input length is 258 cells, allowing one extra cell for malformed-length validation.

The output contains the resulting payloads as little-endian signed-32-bit values and the function returns `4 * list_length`, up to 1024 bytes. A valid empty list returns zero bytes, but output storage must still be nonnull. Invalid input returns `-1` before output checks; a null output pointer or insufficient capacity returns `-2` without writing.

## Workload and source

[`workload.json`](workload.json) covers empty and singleton lists, group sizes one and larger than the list, multiple complete groups, a short trailing group, the maximum list length, invalid group sizes and lengths, null pointers, and output capacity boundaries.

The source’s `reverseKGroup` method counts the list nodes and reverses exactly `k` nodes when at least `k` remain. Its helper returns the current head unchanged when fewer than `k` remain. Values are not inspected or transformed.

- Java [`ReverseKGroup.java`](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/datastructures/lists/ReverseKGroup.java)

## Ports

| Language | Source |
| --- | --- |
| C | [`c/r/reverse_kgroup.c`](../../../c/r/reverse_kgroup.c) |
| C3 | [`c3/r/reverse_kgroup.c3`](../../../c3/r/reverse_kgroup.c3) |
| C++ | [`cpp/r/reverse_kgroup.cpp`](../../../cpp/r/reverse_kgroup.cpp) |
| Elisa | [`elisa/r/reverse_kgroup.elisa`](../../../elisa/r/reverse_kgroup.elisa) |
| Nim | [`nim/r/reverse_kgroup.nim`](../../../nim/r/reverse_kgroup.nim) |
| Odin | [`odin/r/reverse_kgroup.odin`](../../../odin/r/reverse_kgroup.odin) |
| Rust | [`rust/r/reverse_kgroup.rs`](../../../rust/r/reverse_kgroup.rs) |
| V | [`v/r/reverse_kgroup.v`](../../../v/r/reverse_kgroup.v) |
| Zig | [`zig/r/reverse_kgroup.zig`](../../../zig/r/reverse_kgroup.zig) |

## Build and run

```sh
python3 benchmarks/build_abi.py --family i32_array_bytes_output --algorithm reverse_kgroup --language rust
python3 benchmarks/run_i32_array_bytes_output.py --build-manifest build/i32_array_bytes_output/r/reverse_kgroup/rust/build.json
```
