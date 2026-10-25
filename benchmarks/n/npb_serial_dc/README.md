# NPB serial DC

This package covers the data-cube grouping and measure aggregation in the NAS Parallel Benchmarks 3.3 serial `dc` benchmark. It creates one grouped view for every nonempty subset of the input attributes. Duplicate projected keys merge by summing their measures, and each view's groups are ordered lexicographically before contributing to the result.

## Contract

The scalar ABI is `int64_t npb_serial_dc(const int64_t *input, size_t length)`. Input is packed as `[dimension_count, row_count, row_0_attribute_0, ..., row_0_attribute_(d-1), row_0_measure, ...]`. Dimensions are limited to 1 through 5, rows to 1 through 16, attribute values to 0 through 7, and measures to 0 through 1000. The exact input length is `2 + row_count * (dimension_count + 1)`. Invalid or malformed inputs return `-1`.

For each subset mask from 1 through `(1 << dimension_count) - 1`, the implementation projects every row onto the selected attributes, groups equal keys, sums each group's measures, and sorts the groups by projected key. It returns a deterministic signed 64-bit checksum over the subset mask, group count, ordered keys, and measure sums. All intermediates fit signed 64-bit under the stated bounds. The result preserves the NPB benchmark's multidimensional group-by and aggregation workload while keeping fixtures small and deterministic.

The bounded ports use fixed-size arrays and insertion sorting. They omit generated input files, external parameter files, temporary view files, memory-pool sizing, and the benchmark's class-specific subset schedule. This package includes all nonempty views so the complete projection and aggregation behavior is explicit in each call.

## Workload and oracle

[`workload.json`](workload.json) exercises multiple overlapping projections, duplicate projected keys, lexicographic group ordering, the maximum dimension and row bounds, and malformed inputs. [`benchmarks/npb_serial_dc_oracle.py`](../../npb_serial_dc_oracle.py) independently groups rows with Python dictionaries and sorts the projected keys.

## Ports

| Language | Source |
| --- | --- |
| C | [`c/n/npb_serial_dc.c`](../../../c/n/npb_serial_dc.c) |
| C3 | [`c3/n/npb_serial_dc.c3`](../../../c3/n/npb_serial_dc.c3) |
| C++ | [`cpp/n/npb_serial_dc.cpp`](../../../cpp/n/npb_serial_dc.cpp) |
| Elisa | [`elisa/n/npb_serial_dc.elisa`](../../../elisa/n/npb_serial_dc.elisa) |
| Nim | [`nim/n/npb_serial_dc.nim`](../../../nim/n/npb_serial_dc.nim) |
| Odin | [`odin/n/npb_serial_dc.odin`](../../../odin/n/npb_serial_dc.odin) |
| Rust | [`rust/n/npb_serial_dc.rs`](../../../rust/n/npb_serial_dc.rs) |
| V | [`v/n/npb_serial_dc.v`](../../../v/n/npb_serial_dc.v) |
| Zig | [`zig/n/npb_serial_dc.zig`](../../../zig/n/npb_serial_dc.zig) |

## Source and rights

The source is pinned to [`lac-dcc/Benchmarks` at `5d7b75df749241efa7a6e6f5be613d3fcc5cce38`](https://github.com/lac-dcc/Benchmarks/tree/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/NPB-serial/dc). The inspected files are `dc.c`, `adc.c`, `extbuild.c`, `rbt.c`, `ADC.par`, and `info.sh`. The launcher requests ten million input tuples and an external parameter file; this package keeps only the bounded grouping behavior.

The source notice grants permission to use, copy, distribute, and modify the software for any purpose, with or without fee, and requests reference to NAS Parallel Benchmarks 3.3. It provides the software without express or implied warranty. Each port includes this notice and identifies the packed-input/checksum adaptation. The ports are clean-room implementations of the bounded contract rather than copies of the upstream C files.

> NAS Parallel Benchmarks 3.3, serial version, DC. Permission to use, copy, distribute and modify this software for any purpose with or without fee is hereby granted. We request, however, that all derived work reference the NAS Parallel Benchmarks 3.3. This software is provided "as is" without express or implied warranty.
