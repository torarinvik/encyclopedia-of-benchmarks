# Embench EDN Q15 vector multiply-add

This package isolates `vec_mpy1` from the pinned EDN DSP benchmark. For each element it adds the Q15-scaled product `(scaler * x[i]) >> 15` to the initial `y[i]`. Input is `[count, y[count], x[count], scaler]`; `count` is 1–64, and all vector/scaler values are bounded to `[-1024,1023]` so the source's short result remains in range. Signed right shift is arithmetic (floor division by 2^15).

The output contains updated `y` values as little-endian signed 64-bit words. Invalid input returns `-1`; null or insufficient output capacity returns `-2` without writes. The package measures the fixed-point vector multiply-add core; EDN's 150-element harness, shared input initialization, repetition scaling, and other kernels are excluded.

Pinned source: [`vec_mpy1` in `src/edn/libedn.c`](https://github.com/embench/embench-iot/blob/09c2ed8c3b7008c95d08b038de4a3f6dc103ed70/src/edn/libedn.c), commit `09c2ed8c3b7008c95d08b038de4a3f6dc103ed70`. The source is SPDX GPL-3.0-or-later and records WCET Benchmarks provenance and email permission from Björn Lisper to license under GPL. See [`LICENSE.txt`](LICENSE.txt) and [`NOTICE.txt`](NOTICE.txt) for full rights/attribution.

The independent oracle is [`benchmarks/edn_vec_mpy1_oracle.py`](../../edn_vec_mpy1_oracle.py); examples and malformed cases are in [`workload.json`](workload.json). The nine ports implement this bounded source operation; no runtime verification is claimed.
