# Miscellaneous FLOPS kernels

This package groups the eight distinct floating-point kernels in Al Aburto's
FLoPS.c v2.0 family. The unnumbered `Misc/flops` launcher runs the family;
`flops-1` through `flops-8` isolate modules 1 through 8. The modules are not
duplicates: module 1 integrates a rational function, module 2 accumulates an
alternating series for pi, and modules 3 through 8 use different polynomial or
rational integrands and operation mixes. Local `ansibench_whetstone` is another
floating-point workload with different kernels; generic midpoint/trapezoid
packages do not implement these fixed source functions.

## Contract

The `i64_array_float64` ABI accepts `[module, steps]`, where `module` is 1–8
and `steps` is 2–128. It returns the bounded module's deterministic binary64
numerical result. Module 1 uses `2*steps` intervals to preserve the source's
doubling of its integration count. Module 2 runs both alternating loops for
`steps` iterations. Modules 3–8 use `steps` intervals and preserve the
source-ordered polynomial/rational calculations. The source's wall-clock
calibration, timing output, compiler-specific timer, and display-only scaled
error values are omitted; those do not define portable mathematical results.
Malformed or out-of-range input returns `-1e300`.

The Python oracle independently evaluates all eight bounded paths. The workload
has one valid case per module plus invalid module, iteration, and framing cases.
It uses the source's double-precision coefficient set and operation order.

## Provenance and license status

Pinned source: [`lac-dcc/Benchmarks` at
`5d7b75df749241efa7a6e6f5be613d3fcc5cce38`](https://github.com/lac-dcc/Benchmarks/tree/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/Misc).
The source identifies FLoPS.c v2.0 as authored by Al Aburto on 18 Dec 1992.
The pinned source files and launchers provide that attribution but contain no
explicit license or redistribution grant. This package records that status;
the ports are independently written implementations of the described
mathematical kernels, not copies of the C source. No broader license is
asserted for the upstream files.

The eight standalone sources are listed in
[`workload.json`](workload.json). The full family source is `Misc/flops/flops.c`;
the isolated variants are `Misc/flops-1/flops-1.c` through
`Misc/flops-8/flops-8.c`, each launched by its neighboring `info.sh`.

## Language ports

| Language | Source |
| --- | --- |
| C | [c/m/misc_flops.c](../../../c/m/misc_flops.c) |
| C3 | [c3/m/misc_flops.c3](../../../c3/m/misc_flops.c3) |
| C++ | [cpp/m/misc_flops.cpp](../../../cpp/m/misc_flops.cpp) |
| Elisa | [elisa/m/misc_flops.elisa](../../../elisa/m/misc_flops.elisa) |
| Nim | [nim/m/misc_flops.nim](../../../nim/m/misc_flops.nim) |
| Odin | [odin/m/misc_flops.odin](../../../odin/m/misc_flops.odin) |
| Rust | [rust/m/misc_flops.rs](../../../rust/m/misc_flops.rs) |
| V | [v/m/misc_flops.v](../../../v/m/misc_flops.v) |
| Zig | [zig/m/misc_flops.zig](../../../zig/m/misc_flops.zig) |
