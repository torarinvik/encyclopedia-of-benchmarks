# Character occurrence counts

Count the occurrences of each character in an input string. The benchmark
passes a sequence of ASCII codepoints and returns the source map as a stable
byte encoding: ascending decimal codepoints and counts joined as
`codepoint=count` pairs separated by commas. For example, `[98, 97, 98]`
produces `97=1,98=2`. The source map has no iteration-order guarantee, so
sorting its keys preserves the map contents while making comparison portable.

## Contract

- Input is an array of 0 to 128 signed 64-bit ASCII codepoints, each in 0..127.
- Return the number of bytes written and emit the canonical sorted map.
- Empty input returns zero bytes, representing the empty map.
- Invalid length or codepoint returns -1 without writing output.
- If the output buffer is smaller than the canonical map, return -2 without
  writing output.
- A null input pointer with nonempty input returns -1; a null output pointer
  for a nonempty encoded map returns -2.
- The domain is restricted to ASCII; the pinned Go source accepts Unicode
  strings and counts their Unicode codepoints as runes.

## Workload and oracle

[`workload.json`](workload.json) includes duplicates, numeric key ordering,
empty input, invalid codepoints, maximum input length, and insufficient output
capacity. The independent oracle is
[`charoccurrence_oracle.py`](../../charoccurrence_oracle.py).

Verify the ports and workload with:

```sh
python3 benchmarks/verify_i64_array_bytes_output.py --algorithm charoccurrence
```

Run the nine ports against the oracle with
`python3 benchmarks/verify_i64_array_bytes_output.py --algorithm charoccurrence`.

## Pinned source

[TheAlgorithms/Go `strings/charoccurrence.go`](https://github.com/TheAlgorithms/Go/blob/5ba447ec5ff3d1213de65b92e726ee74c5d5cc19/strings/charoccurrence.go)
implements `CountChars` by ranging over the string's runes and incrementing a
map entry for each rune.

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/c/charoccurrence.c`](../../../c/c/charoccurrence.c) |
| C3 | [`c3/c/charoccurrence.c3`](../../../c3/c/charoccurrence.c3) |
| C++ | [`cpp/c/charoccurrence.cpp`](../../../cpp/c/charoccurrence.cpp) |
| Elisa | [`elisa/c/charoccurrence.elisa`](../../../elisa/c/charoccurrence.elisa) |
| Nim | [`nim/c/charoccurrence.nim`](../../../nim/c/charoccurrence.nim) |
| Odin | [`odin/c/charoccurrence.odin`](../../../odin/c/charoccurrence.odin) |
| Rust | [`rust/c/charoccurrence.rs`](../../../rust/c/charoccurrence.rs) |
| V | [`v/c/charoccurrence.v`](../../../v/c/charoccurrence.v) |
| Zig | [`zig/c/charoccurrence.zig`](../../../zig/c/charoccurrence.zig) |
