# Number container system

This benchmark follows the pinned Python `NumberContainer`. `change(index, number)` replaces the value stored at an index; `find(number)` returns the smallest index currently holding that number or `-1`. The implementation maintains sorted index lists for each number, while the bounded ports preserve the same observable results.

## Contract

- The ABI is `i64_array_bytes_output`. Input is `[operation_count, (opcode, a, b)...]`, with 0–32 exact triplets. Change is `[0, index, number]`, where index is 0–63 and number is -100–100. Find is `[1, number, 0]`; its third word is reserved and must be zero. The maximum input length is 97 signed-i64 words.
- Output is one ASCII decimal result per find operation, separated by commas with no trailing comma. A trace without finds returns an empty byte string and byte count 0. The largest output is 95 bytes: 32 two-character answers separated by 31 commas.
- The ports may reserve a 128-byte output workspace, but the maximum encoded result is 95 bytes. Invalid or null input returns `-1` before output-buffer checks. For valid input, a null output pointer returns `-2`; insufficient capacity also returns `-2` without writes. A nonnull pointer with capacity zero succeeds when the output is empty.

The bounded workload, including malformed traces and output-buffer cases, is in [workload.json](workload.json). The independent oracle is [benchmarks/number_container_system_oracle.py](../../number_container_system_oracle.py).

Pinned source: [TheAlgorithms/Python `number_container_system.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/other/number_container_system.py) at commit `e1a2a8b016001309a73d5fec4818c35cca139795`.

## Reproduce

~~~
python3 benchmarks/build_abi.py --family i64_array_bytes_output --algorithm number_container_system --language rust
python3 benchmarks/run_i64_array_bytes_output.py --algorithm number_container_system
python3 benchmarks/verify_i64_array_bytes_output.py --algorithm number_container_system --languages rust
~~~

## Language ports

| Language | Source |
| --- | --- |
| C | [c/o/number_container_system.c](../../../c/o/number_container_system.c) |
| C3 | [c3/o/number_container_system.c3](../../../c3/o/number_container_system.c3) |
| C++ | [cpp/o/number_container_system.cpp](../../../cpp/o/number_container_system.cpp) |
| Elisa | [elisa/o/number_container_system.elisa](../../../elisa/o/number_container_system.elisa) |
| Nim | [nim/o/number_container_system.nim](../../../nim/o/number_container_system.nim) |
| Odin | [odin/o/number_container_system.odin](../../../odin/o/number_container_system.odin) |
| Rust | [rust/o/number_container_system.rs](../../../rust/o/number_container_system.rs) |
| V | [v/o/number_container_system.v](../../../v/o/number_container_system.v) |
| Zig | [zig/o/number_container_system.zig](../../../zig/o/number_container_system.zig) |
