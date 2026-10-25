# Rodinia HybridSort bounded histogram and merge sort

This package implements the Rodinia HybridSort pattern: partition values into histogram buckets, scatter them into bucket ranges, and merge-sort each range. It preserves the source's 1024-bin float bucket mapping, but uses uniform bins on the bounded input interval instead of the CUDA source's data-adaptive quantile pivot construction. This makes the contract deterministic and keeps the defining bucket-then-merge structure.

## Contract

- ABI: `i64_array_bytes_output`; exported symbol: `rodinia_hybridsort`.
- Input: `[count, q0, q1, ...]`, exactly `count + 1` signed 64-bit values. There are 2–64 items. Each item is an integer from 0 through 1,000,000 in multiples of 1,000, and at least two distinct values must occur.
- Each q is converted to binary32 as `f32(q) / f32(1,000,000)`. The minimum and maximum are derived with the same conversion. The bin index is the truncated binary32 value `((value - minimum) / (maximum - minimum)) * 1024`, clamped to 0–1023.
- The implementation counts bins, forms prefix offsets, scatters values in input order, and merge-sorts each bucket in place. Since the bin mapping is monotone, concatenating the sorted bins yields the globally sorted input values.
- Output is the sorted original q values, encoded as signed 64-bit little-endian integers. Duplicates are retained. The successful return value is `8 * count` bytes. Invalid input returns `-1`; null or short output returns `-2` without writes.
- The q quantum and closed range keep distinct q values separated at binary32 precision while still exercising the source's float bucket calculations. The largest frame is 65 i64 values and 512 output bytes.

The Python oracle uses a comparison sort and independently validates the same framing and bounds; it does not reproduce histogram bucketing or merge sort. Static fixtures cover unsorted values, duplicates, range endpoints, malformed frames, and output errors.

## Source and rights

- Pinned source: [`cuda/hybridsort`](https://github.com/utcs-scea/rodinia/tree/f30e63663cfb114939a15c7ffc4ae112055ae6a8/cuda/hybridsort), Rodinia commit `f30e63663cfb114939a15c7ffc4ae112055ae6a8`.
- The source uses seeded random floats and a CUDA histogram/pivot workflow. This package accepts values explicitly and replaces data-adaptive quantile pivots with uniform interval bins; it does not reproduce the launcher, timing wrapper, or GPU-specific kernels.
- Rodinia's University of Virginia redistribution terms and citation request are reproduced in [`LICENSE.txt`](LICENSE.txt).
- The NVIDIA histogram example's complete notice, disclaimer, and U.S. Government end-user notice are reproduced in [`NVIDIA_NOTICE.txt`](NVIDIA_NOTICE.txt), as required by the pinned histogram source. The implementations are independent ports of the bounded algorithm profile.

## Files

- Nine language ports are in `c/r`, `c3/r`, `cpp/r`, `elisa/r`, `nim/r`, `odin/r`, `rust/r`, `v/r`, and `zig/r`.
- Independent oracle: [`benchmarks/rodinia_hybridsort_oracle.py`](../../rodinia_hybridsort_oracle.py).
- Workload and fixtures: [`workload.json`](workload.json).
