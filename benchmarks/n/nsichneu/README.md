# Embench NSICHNEU bounded Petri/T-Net profile

## Contract

This package models the fixed NSicherNeu place/transition net from Embench's generated `nsichneu` benchmark. Input is `[run_count, P1[0..2], P2[0..4]]`; the source counts are reset to P1=3, P2=5, P3=0 for each run. P1 and P2 marking arrays persist across runs, while P3 starts with six zero slots. The bounded input explicitly supplies the initial P1 and P2 marking values so the transition guards can be exercised; the all-zero case reproduces the source benchmark's verified initial marking, where no transition fires.

The operation checks the six P1 permutations in source order. A matching triple with the final two values equal and `x < y` consumes three P1 marks and appends `[x, y, x-y]` to P3. It then checks the 120 four-slot P2 permutations in source subset/permutation order. Three equal tail values with `y > x` consume four P2 marks and append `[x, y, x+y]` to P3. The output snapshot contains each place's final mark count followed by every fixed-size marking array: P1 count and 3 values, P2 count and 5 values, P3 count and 6 values. Values are encoded as 17 little-endian signed 64-bit integers (136 bytes).

`run_count` is 1–64; each marking value is in `[-1000,1000]`. Invalid input returns `-1`; a null or short output buffer returns `-2` without writes. This is a bounded profile of this generated net, not a general Petri-net interpreter.

## Workload and oracle

[`workload.json`](workload.json) covers the source's all-zero no-transition state, both P1 and P2 transition families (including later permutation/subset paths), repeated execution, unchanged equal-operand cases, and malformed/capacity inputs. The independent source-ordered oracle is [`benchmarks/nsichneu_oracle.py`](../../nsichneu_oracle.py).

## Source and rights

- Pinned source: [`src/nsichneu/libnsichneu.c`](https://github.com/embench/embench-iot/blob/de24bdf561f4eaad7f37685641fa301f2b8b4bc3/src/nsichneu/libnsichneu.c) at commit `de24bdf561f4eaad7f37685641fa301f2b8b4bc3`.
- The source declares `GPL-3.0-or-later` and identifies the generated model as NSicherNeu from C-LAB, Paderborn, based on a Sea2CHaRy description. It credits Friedhelm Stappert for maintenance and modifications. The source license text is retained in [`LICENSE.txt`](LICENSE.txt).
- These ports were written independently from the documented transition behavior; no upstream code was copied or translated.

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/n/nsichneu.c`](../../../c/n/nsichneu.c) |
| C3 | [`c3/n/nsichneu.c3`](../../../c3/n/nsichneu.c3) |
| C++ | [`cpp/n/nsichneu.cpp`](../../../cpp/n/nsichneu.cpp) |
| Elisa | [`elisa/n/nsichneu.elisa`](../../../elisa/n/nsichneu.elisa) |
| Nim | [`nim/n/nsichneu.nim`](../../../nim/n/nsichneu.nim) |
| Odin | [`odin/n/nsichneu.odin`](../../../odin/n/nsichneu.odin) |
| Rust | [`rust/n/nsichneu.rs`](../../../rust/n/nsichneu.rs) |
| V | [`v/n/nsichneu.v`](../../../v/n/nsichneu.v) |
| Zig | [`zig/n/nsichneu.zig`](../../../zig/n/nsichneu.zig) |
