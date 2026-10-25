# Embench EDN cascaded IIR sections

This package isolates EDN's `iir1` kernel: one input sample passes in order through a bounded cascade of first-order state-pair sections. Each section reads four short coefficients and two long state values, computes `t = x + ((c2*s0 + c3*s1) >> 15)`, then `x = t + ((c0*s0 + c1*s1) >> 15)`, shifts `s1 = s0`, and stores `s0 = t`. This differs from the local direct-form order-1-to-3 streaming IIR recurrence and from Butterworth coefficient design.

Input is `[section_count, input_sample, coefficients[4*section_count], states[2*section_count]]`; sections are 1–8 and all supplied signed values are in `[-1024,1023]`. Output is the final sample followed by all updated section state pairs, as little-endian signed 64-bit words. Arithmetic right shifts use the source's fixed-point Q15 behavior. Invalid input returns `-1`; null/short capacity returns `-2` without writes. The full source benchmark uses 50 sections and shares state arrays produced by earlier EDN kernels; that harness and cross-kernel data flow are excluded.

Pinned source is `iir1` in [`src/edn/libedn.c`](https://github.com/embench/embench-iot/blob/09c2ed8c3b7008c95d08b038de4a3f6dc103ed70/src/edn/libedn.c), commit `09c2ed8c3b7008c95d08b038de4a3f6dc103ed70`. The source header records WCET Benchmarks provenance, Embecosm/Bristol contributors, GPL-3.0-or-later, and permission obtained by email from Björn Lisper. Full license and attribution are bundled in [`LICENSE.txt`](LICENSE.txt) and [`NOTICE.txt`](NOTICE.txt).

See [`workload.json`](workload.json) and [`benchmarks/edn_iir_cascade_oracle.py`](../../edn_iir_cascade_oracle.py). The nine ports implement this bounded source kernel; no runtime verification is claimed.
