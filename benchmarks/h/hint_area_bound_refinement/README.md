# Bounded integer HINT area-bound refinement

This package is a deterministic, bounded fixed-point variant of HINT's hierarchical integration kernel. It exposes the interval subdivision and area-bound refinement, not HINT's timing driver, QUIPS measurement, or official benchmark result.

## Contract

The `i64_array_bytes_output` input is exactly `[x_bits, y_bits, requested_splits]`. The first two values are in `1..=8`, with their sum at most 16. They define dyadic scales `scx = 2^x_bits` and `scy = 2^y_bits`; `dmax = scx*scy - 1`. Requested splits are in `0..=min(64, scx-1)`. All calculations use signed 64-bit integer arithmetic.

At a split point `x`, the kernel computes the lower function value by integer floor division of `scy*(scx-x)/(scx+x)`. Its upper function value is that floor plus one exactly when the division has a nonzero remainder. Thus the rational curve is bounded without floating-point rounding. The kernel starts with the full interval, then repeatedly takes the next interval from HINT's descending-error queue, splits it at its dyadic midpoint, and replaces its parent lower/upper area contributions with the children's contributions. The larger-error child is queued first; equal errors preserve left-before-right order, matching the source insertion rule. If the source's queue termination condition reports `DISCRET`, that status is returned in the result instead of being treated as malformed input.

The output is five signed i64 values in little-endian order: `[kernel_status, actual_splits, lower_area, upper_area, upper_area-lower_area]`. Kernel status is `0` for `NOERROR` and `1` for `DISCRET`. Success returns 40 bytes. Invalid framing or values return `-1`; null output or capacity below 40 returns `-2`. Output is untouched on errors.

All coordinates, interval widths, and function values are at most 256; denominators are at most 512; and `scx*scy` is at most 65536. Function numerators are at most 65536 and `denominator*floor_value` is at most 131072. Each rectangle area term is at most 65536, while each accumulated bound stays within the area of the full grid (at most 65536). A conservative bound on either child-error calculation is below 200000: each function-value difference has magnitude at most 256, each width factor at most 255, and the clamped correction term is at most 65536. These bounds also cover a zero-width rectangle. Every intermediate therefore fits signed 64-bit arithmetic with a wide margin.

## Source and license

The operation follows the independently reimplemented integer kernel in [`hint/src/hkernel.c` at `nfinit/ansibench` commit `ef90abd09d7b7bb1f2809f896d6f67fb9724bebe`](https://github.com/nfinit/ansibench/blob/ef90abd09d7b7bb1f2809f896d6f67fb9724bebe/hint/src/hkernel.c), with context from [`hint/include/hint.h`](https://github.com/nfinit/ansibench/blob/ef90abd09d7b7bb1f2809f896d6f67fb9724bebe/hint/include/hint.h) and [`hint/include/typedefs.h`](https://github.com/nfinit/ansibench/blob/ef90abd09d7b7bb1f2809f896d6f67fb9724bebe/hint/include/typedefs.h). HINT was designed by John Gustafson and Quinn Snell; the source carries Copyright © 1994 Iowa State University Research Foundation, Inc. It is distributed under GPL-2.0; preserve the license and notices when redistributing this derivative. The pinned upstream [`hint/LICENSE`](https://github.com/nfinit/ansibench/blob/ef90abd09d7b7bb1f2809f896d6f67fb9724bebe/hint/LICENSE) is included as [`LICENSE`](LICENSE).

## Workload and oracle

[`workload.json`](workload.json) covers small exact cases, bounded limits, invalid inputs, and output errors. The independent oracle is [`benchmarks/hint_area_bound_refinement_oracle.py`](../../hint_area_bound_refinement_oracle.py).

| Language | Port |
|---|---|
| C | [`c/h/hint_area_bound_refinement.c`](../../../c/h/hint_area_bound_refinement.c) |
| C3 | [`c3/h/hint_area_bound_refinement.c3`](../../../c3/h/hint_area_bound_refinement.c3) |
| C++ | [`cpp/h/hint_area_bound_refinement.cpp`](../../../cpp/h/hint_area_bound_refinement.cpp) |
| Elisa | [`elisa/h/hint_area_bound_refinement.elisa`](../../../elisa/h/hint_area_bound_refinement.elisa) |
| Nim | [`nim/h/hint_area_bound_refinement.nim`](../../../nim/h/hint_area_bound_refinement.nim) |
| Odin | [`odin/h/hint_area_bound_refinement.odin`](../../../odin/h/hint_area_bound_refinement.odin) |
| Rust | [`rust/h/hint_area_bound_refinement.rs`](../../../rust/h/hint_area_bound_refinement.rs) |
| V | [`v/h/hint_area_bound_refinement.v`](../../../v/h/hint_area_bound_refinement.v) |
| Zig | [`zig/h/hint_area_bound_refinement.zig`](../../../zig/h/hint_area_bound_refinement.zig) |
