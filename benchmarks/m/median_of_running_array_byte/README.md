# Running median for signed bytes

This benchmark specializes the pinned Java `MedianOfRunningArrayByte` subclass. It reports the median after each insertion into a growing stream of signed byte values.

## Contract

- The ABI is `i32_array_bytes_output`. Input is signed-i32 words `[sample_count, sample_0, ..., sample_(count-1)]`. The count is 1–64, each sample is in the Java signed-byte range `[-128,127]`, and the exact length is `1 + sample_count`. The maximum valid input is 65 words; one extra word is accepted only so malformed trailing data can be rejected.
- The output has one median for each nonempty prefix, in insertion order. The pinned base class inserts into the max-heap only when the min-heap is nonempty and a sample is strictly less than its root; otherwise it inserts into the min-heap. It moves one root only when one heap exceeds the other by more than one element. For an odd-sized prefix, `getMedian()` returns the root of whichever heap is larger; either root is the center byte because the heaps remain ordered and their sizes differ by one. For even-sized prefixes, the source promotes both roots to `int`, computes `(maxHeapRoot + minHeapRoot) / 2` with Java division truncating toward zero, then casts the result back to `byte`. The result is written as one raw two's-complement byte. Success returns `sample_count`, from 1 through 64.
- The independent oracle sorts each prefix rather than reproducing the source's heap layout. That yields the same observable center byte for odd prefixes and the same two middle values for even prefixes. Empty input is invalid because the source's `getMedian()` throws when the heaps are empty.
- Invalid framing, count, or sample values and a null input pointer return `-1` before output checks. A null output pointer or capacity below `sample_count` returns `-2` without writes.

The workload covers both insertion directions, duplicate and extreme byte values, even-prefix truncation for negative sums, heap rebalancing, maximum length, malformed inputs, and output-buffer errors. See [workload.json](workload.json) and the independent [oracle](../../median_of_running_array_byte_oracle.py).

The subclass is [Java `MedianOfRunningArrayByte`](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/misc/MedianOfRunningArrayByte.java). It inherits the two-heap implementation from [Java `MedianOfRunningArray`](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/misc/MedianOfRunningArray.java). Both are pinned at commit `e43ec3897e48f23843972d02cd05a5bb1b6864a2`.

## Reproduce

~~~
python3 benchmarks/build_abi.py --family i32_array_bytes_output --algorithm median_of_running_array_byte --language rust
python3 benchmarks/run_i32_array_bytes_output.py --algorithm median_of_running_array_byte
python3 benchmarks/verify_i32_array_bytes_output.py --algorithm median_of_running_array_byte --languages rust
~~~

## Language ports

- C: [c/m/median_of_running_array_byte.c](../../../c/m/median_of_running_array_byte.c)
- C3: [c3/m/median_of_running_array_byte.c3](../../../c3/m/median_of_running_array_byte.c3)
- C++: [cpp/m/median_of_running_array_byte.cpp](../../../cpp/m/median_of_running_array_byte.cpp)
- Elisa: [elisa/m/median_of_running_array_byte.elisa](../../../elisa/m/median_of_running_array_byte.elisa)
- Nim: [nim/m/median_of_running_array_byte.nim](../../../nim/m/median_of_running_array_byte.nim)
- Odin: [odin/m/median_of_running_array_byte.odin](../../../odin/m/median_of_running_array_byte.odin)
- Rust: [rust/m/median_of_running_array_byte.rs](../../../rust/m/median_of_running_array_byte.rs)
- V: [v/m/median_of_running_array_byte.v](../../../v/m/median_of_running_array_byte.v)
- Zig: [zig/m/median_of_running_array_byte.zig](../../../zig/m/median_of_running_array_byte.zig)
