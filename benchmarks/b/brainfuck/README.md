# Brainfuck interpreter

This benchmark ports the pinned TheAlgorithms/Lua [Brainfuck interpreter](https://github.com/TheAlgorithms/Lua/blob/cedc141018ad48884318fe08a6db278664b17128/src/esolang/brainfuck.lua). It first pairs brackets, then executes the eight Brainfuck commands over unsigned byte cells. Other printable ASCII program characters are ignored. Input exhaustion supplies zero bytes, matching the source.

## Input and output

Input is a signed 64-bit array `[program_length, program_byte..., input_length, input_byte...]`. Programs contain 0..2,048 printable ASCII bytes; input contains 0..1,024 arbitrary bytes. Output is the raw byte stream emitted by `.`.

The benchmark bounds execution to 100,000 instruction steps, the tape pointer to -128..128 from its initial cell, and output to 8,192 bytes. Unmatched brackets, limit overruns, malformed arrays, and insufficient output capacity return `-2`. The source uses an unbounded tape; the stated tape and step bounds define a finite portable benchmark contract.

## Workloads

The workload covers byte arithmetic and wraparound, input and EOF, leftward tape movement, skipped and nested loops, Hello World, ignored text, malformed brackets, pointer and execution bounds, output bounds, and insufficient output capacity.

## Build and verification

```sh
python3 benchmarks/build_abi.py --family i64_array_bytes_output --algorithm brainfuck --language rust
python3 benchmarks/run_i64_array_bytes_output.py --build-manifest build/i64_array_bytes_output/b/brainfuck/rust/build.json
python3 benchmarks/verify_i64_array_bytes_output.py --algorithm brainfuck --languages rust
```

| Language | Source |
| --- | --- |
| C | [`c/b/brainfuck.c`](../../../c/b/brainfuck.c) |
| C3 | [`c3/b/brainfuck.c3`](../../../c3/b/brainfuck.c3) |
| C++ | [`cpp/b/brainfuck.cpp`](../../../cpp/b/brainfuck.cpp) |
| Elisa | [`elisa/b/brainfuck.elisa`](../../../elisa/b/brainfuck.elisa) |
| Nim | [`nim/b/brainfuck.nim`](../../../nim/b/brainfuck.nim) |
| Odin | [`odin/b/brainfuck.odin`](../../../odin/b/brainfuck.odin) |
| Rust | [`rust/b/brainfuck.rs`](../../../rust/b/brainfuck.rs) |
| V | [`v/b/brainfuck.v`](../../../v/b/brainfuck.v) |
| Zig | [`zig/b/brainfuck.zig`](../../../zig/b/brainfuck.zig) |
