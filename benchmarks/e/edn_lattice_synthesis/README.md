# Embench EDN lattice synthesis

This package isolates the `latsynth` fixed-point lattice synthesis recurrence in the pinned EDN DSP source. Input is `[order, initial_f, b..., k...]`, with order 1–16, initial accumulator in `[-65536,65535]`, and signed state/coefficient values in `[-1024,1023]`. The operation first subtracts the final state/coefficient product, then visits earlier stages in descending order, subtracting each product and updating the next state by `b[i] + ((k[i] * (f >> 16)) >> 16)`. It finally assigns `b[0] = f >> 16` and returns `f`.

Output is `(order+1)` little-endian signed 64-bit words: returned `f`, then the updated state vector. All arithmetic right shifts round toward negative infinity as in the source's common two's-complement target behavior. Bounds keep intermediates in signed 32-bit range and all state updates within the source `short` domain. Invalid frames return `-1`; insufficient/null output returns `-2` without writes.

The upstream benchmark also exercises vector multiply, dot/energy MAC, two FIR implementations, a 50-section IIR cascade, a fixed-point JPEG DCT, and a codebook stub. This package covers only lattice synthesis. It does not reproduce EDN's shared initialized arrays or benchmark harness.

Source: [`latsynth` in `src/edn/libedn.c`](https://github.com/embench/embench-iot/blob/09c2ed8c3b7008c95d08b038de4a3f6dc103ed70/src/edn/libedn.c) at commit `09c2ed8c3b7008c95d08b038de4a3f6dc103ed70`. The file is SPDX GPL-3.0-or-later and records original WCET Benchmarks provenance and email permission from Björn Lisper to license under GPL. Embench header attribution and complete GPL text are in [`NOTICE.txt`](NOTICE.txt) and [`LICENSE.txt`](LICENSE.txt). The nine ports independently implement this bounded contract.

The independent oracle is [`benchmarks/edn_lattice_synthesis_oracle.py`](../../edn_lattice_synthesis_oracle.py). Fixtures are in [`workload.json`](workload.json); no runtime verification is claimed here.
