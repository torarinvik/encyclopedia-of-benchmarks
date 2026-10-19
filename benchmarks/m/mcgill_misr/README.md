# McGill MISR

## Contract

The pinned `misr` launcher passes no options. Its source fixes a 10-cell register, ten vectors per experiment, fault probability 0.25, feedback structure `1000000000`, and seed words `{1, 0, 0}`. The full source default is 100,000 experiments; `SMALL_PROBLEM_SIZE` selects 30,000. The bounded suite profile accepts an experiment count from 1 through 1,000.

Each experiment copies the current fault-free register into the faulty register, runs the source's ten MISR update vectors with its POSIX `lrand48` stream, and counts one mismatch if any of the ten visible cells differ at the end. The random state begins at 1 for each call, as in `seed48({1,0,0})`, and follows `state=(0x5DEECE66D*state+0xB) mod 2^48`; each `lrand48()` result is `state >> 17`. The ports preserve the source's update order and parity masking.

## ABI and output

The C ABI entry point is `mcgill_misr(int64_t experiments, uint8_t *output, size_t output_capacity)`. It returns the exact two-line source report as ASCII, including the source's single leading space before the parameter line. The final field is `(experiments - differing_experiments) / experiments`, formatted with eight digits after the decimal point in scientific notation. Inputs outside 1..1,000 return -1. Null or insufficient output buffers return -2 without writing; output is staged before copying.

The [independent oracle](../../mcgill_misr_oracle.py) models the 48-bit random recurrence and source MISR state transitions directly. It formats the probability from an integer ratio. The workload uses valid short-buffer cases so the ports still execute the bounded simulation before returning -2; null-output cases return early after input validation. It also includes signed and profile-boundary invalid inputs.

## Implementations

| Language | Source |
| --- | --- |
| C | [c/m/mcgill_misr.c](../../../c/m/mcgill_misr.c) |
| C3 | [c3/m/mcgill_misr.c3](../../../c3/m/mcgill_misr.c3) |
| C++ | [cpp/m/mcgill_misr.cpp](../../../cpp/m/mcgill_misr.cpp) |
| Elisa | [elisa/m/mcgill_misr.elisa](../../../elisa/m/mcgill_misr.elisa) |
| Nim | [nim/m/mcgill_misr.nim](../../../nim/m/mcgill_misr.nim) |
| Odin | [odin/m/mcgill_misr.odin](../../../odin/m/mcgill_misr.odin) |
| Rust | [rust/m/mcgill_misr.rs](../../../rust/m/mcgill_misr.rs) |
| V | [v/m/mcgill_misr.v](../../../v/m/mcgill_misr.v) |
| Zig | [zig/m/mcgill_misr.zig](../../../zig/m/mcgill_misr.zig) |

## Pinned source

- [misr.c at the pinned commit](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/McGill/misr/misr.c)
- [info.sh at the pinned commit](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/McGill/misr/info.sh)
