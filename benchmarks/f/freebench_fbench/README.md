# FreeBench Fbench optical ray trace

This package implements a bounded profile of John Walker's Floating Point
Benchmark. The source evaluates a four-surface achromatic telescope: it traces
marginal and paraxial rays through the lens, repeats marginal tracing at two
spectral lines, and computes spherical, sine-condition, and chromatic
aberrations.

## Contract

- ABI: `i64_array_float64`, exported symbol `freebench_fbench`.
- Input is one integer `[passes]` in the range 1 through 16. Pass `p`, starting
  from zero, traces at height `2.0 + 0.0002*p`. The first pass uses the source's
  exact 2.0-unit marginal ray height; subsequent heights form a small bounded
  ray sweep through the same lens. Each pass traces D-line marginal and
  paraxial rays, then C- and F-line marginal rays.
- The lens surfaces, spectral wavelengths, refraction order, paraxial branch,
  trigonometric branch, and aberration expressions follow the pinned source.
- The output is the accumulated sum of longitudinal spherical aberration,
  offense against the sine condition, and axial chromatic aberration for each
  pass. Varying the ray height keeps every pass's ray trace dependent on the
  requested bounded workload. Invalid input returns `-1e300`.
- The upstream launcher hard-codes 1,000,000 repetitions. This profile limits
  that loop to 16 passes; it preserves the ray-tracing kernel and omits the
  timer, console formatting, reference-string comparison, and archival timing
  guidance.

The source header identifies John Walker's Floating Point Benchmark as derived
from the Marinchip Interactive Lens Design System (December 1980). It permits
use, distribution, and modification when origin information is preserved. The
ports and oracle are independent implementations; this package retains source
attribution here and in each port.

- [Pinned `fbench.c`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/Misc/fbench/fbench.c)
- [Pinned `info.sh`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/Misc/fbench/info.sh)
- [Pinned reference output](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/Misc/fbench/fbench.reference_output)

## Language ports

| Language | Source |
| --- | --- |
| C | [c/f/freebench_fbench.c](../../../c/f/freebench_fbench.c) |
| C3 | [c3/f/freebench_fbench.c3](../../../c3/f/freebench_fbench.c3) |
| C++ | [cpp/f/freebench_fbench.cpp](../../../cpp/f/freebench_fbench.cpp) |
| Elisa | [elisa/f/freebench_fbench.elisa](../../../elisa/f/freebench_fbench.elisa) |
| Nim | [nim/f/freebench_fbench.nim](../../../nim/f/freebench_fbench.nim) |
| Odin | [odin/f/freebench_fbench.odin](../../../odin/f/freebench_fbench.odin) |
| Rust | [rust/f/freebench_fbench.rs](../../../rust/f/freebench_fbench.rs) |
| V | [v/f/freebench_fbench.v](../../../v/f/freebench_fbench.v) |
| Zig | [zig/f/freebench_fbench.zig](../../../zig/f/freebench_fbench.zig) |

The independent ray-trace oracle is [`freebench_fbench_oracle.py`](../../freebench_fbench_oracle.py); [`workload.json`](workload.json) describes the bounded profile and cases.
