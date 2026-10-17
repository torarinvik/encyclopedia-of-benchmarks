# SCAN disk scheduling

This benchmark preserves the request ordering and endpoint markers emitted by the pinned Java `ScanScheduling.execute` method. It measures the returned service order, not seek distance.

## Contract

- The ABI is `i32_array_bytes_output`. Input is `[disk_size, head_position, direction, request_count, requests...]` as signed-i32 values and must contain exactly `4 + request_count` words. `disk_size` is in `1..256`, the head position and every request are in `0..disk_size-1`, direction `1` means up and `0` means down, and the request count is in `0..64`. Duplicate requests are retained.
- The source partitions requests at the head: requests below it are the left side, while requests equal to or above it are the right side. Moving up emits the right side in ascending order, then `disk_size - 1`, then the left side in descending order. Moving down emits the left side in descending order, then `0`, then the right side in ascending order.
- A nonempty request list always emits its endpoint marker, even when the marker duplicates a requested position or one partition is empty. An empty request list returns zero bytes and emits no marker.
- Output is the service-order positions serialized as little-endian signed-i32 values. The return value is the number of bytes written, at most 260 bytes for 64 requests and one endpoint marker. Invalid or null input returns `-1` before output-buffer checks. A null output pointer or insufficient capacity returns `-2` without writes. A nonnull output pointer with zero capacity succeeds for an empty request list.

The fixtures in [workload.json](workload.json) cover both directions, head equality, endpoint duplication, empty input, the maximum output, malformed inputs, and output capacity boundaries. The independent oracle is [scan_scheduling_oracle.py](../../scan_scheduling_oracle.py).

Pinned source: [TheAlgorithms/Java `ScanScheduling.java`](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/scheduling/diskscheduling/ScanScheduling.java) at commit `e43ec3897e48f23843972d02cd05a5bb1b6864a2`.

## Reproduce

~~~
python3 benchmarks/build_abi.py --family i32_array_bytes_output --algorithm scan_scheduling --language rust
python3 benchmarks/run_i32_array_bytes_output.py --build-manifest build/i32_array_bytes_output/s/scan_scheduling/rust/build.json
python3 benchmarks/verify_i32_array_bytes_output.py --algorithm scan_scheduling --languages rust
~~~

## Language ports

| Language | Source |
| --- | --- |
| C | [c/s/scan_scheduling.c](../../../c/s/scan_scheduling.c) |
| C3 | [c3/s/scan_scheduling.c3](../../../c3/s/scan_scheduling.c3) |
| C++ | [cpp/s/scan_scheduling.cpp](../../../cpp/s/scan_scheduling.cpp) |
| Elisa | [elisa/s/scan_scheduling.elisa](../../../elisa/s/scan_scheduling.elisa) |
| Nim | [nim/s/scan_scheduling.nim](../../../nim/s/scan_scheduling.nim) |
| Odin | [odin/s/scan_scheduling.odin](../../../odin/s/scan_scheduling.odin) |
| Rust | [rust/s/scan_scheduling.rs](../../../rust/s/scan_scheduling.rs) |
| V | [v/s/scan_scheduling.v](../../../v/s/scan_scheduling.v) |
| Zig | [zig/s/scan_scheduling.zig](../../../zig/s/scan_scheduling.zig) |
