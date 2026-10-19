# Fixed-width string heapsort

Sort fixed-width four-byte ASCII keys in unsigned-byte lexicographic order using an in-place max-heap and extraction. This is a bounded, deterministic kernel corresponding to NBench's String Heapsort operation; it retains the key operation while using fixed-width keys for a compact cross-language ABI.

## Contract

Input is a signed-i64 array `[key_count, byte0, byte1, byte2, byte3, ...]`, with 0–64 keys and each byte in 0..127. The input length must be exactly `1 + 4*key_count`. Output is the sorted keys concatenated as raw bytes, four bytes per key; success returns the byte count. Malformed input returns `-1`. A null output or insufficient capacity returns `-2` with no writes, including for empty output. Maximum input length is 257 i64 values and maximum output is 256 bytes.

The heap compares each key byte as an unsigned value, from byte zero through byte three, and uses strict lexicographic order. Equal keys remain equal; stability is not promised. Heap construction is bottom-up, followed by max extraction to the array suffix.

## Upstream attribution and terms

This is a new bounded implementation based on the operation description in ANSIbench's NBench BYTEmark source, `nbench/src/nbench1.c` (`StrHeapSort`, `str_is_less`), pinned at [nfinit/ansibench commit `ef90abd09d7b7bb1f2809f896d6f67fb9724bebe`](https://github.com/nfinit/ansibench/blob/ef90abd09d7b7bb1f2809f896d6f67fb9724bebe/nbench/src/nbench1.c). NBench credits Rick Grehan/BYTE Magazine for BYTEmark and Uwe F. Mayer for the Linux/Unix port. No source blocks are copied.

The upstream BYTEmark notice makes the source, executable, and documentation available “as is” and disclaims warranties and liability. Preserve that notice and upstream attribution when redistributing derived work; the upstream package is commonly tagged `freedist`, not a standard permissive license. The notice is included as [NBENCH-LICENSE](NBENCH-LICENSE) and is also available at [`nbench/LICENSE`](https://github.com/nfinit/ansibench/blob/ef90abd09d7b7bb1f2809f896d6f67fb9724bebe/nbench/LICENSE).

## ABI

Uses `i64_array_bytes_output`: exported `string_heap_sort(values, length, output, output_capacity)` returns the number of bytes written, `-1` for invalid input, and `-2` for null/short output.
