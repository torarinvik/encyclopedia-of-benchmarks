# Olden power pricing kernel

This package ports a bounded kernel from the Olden `power` benchmark in
[`lac-dcc/Benchmarks`](https://github.com/lac-dcc/Benchmarks/tree/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/Olden/power).
The upstream program models power demand through a feeder, lateral, branch,
and leaf tree. The local profile keeps one feeder, one lateral, one branch,
and one through four leaves.

## Bounded contract

- ABI: `i64_array_scalar`, function symbol `olden_power`.
- Input is `[leaf_count, compute_passes]`, with `leaf_count` in 1..4 and
  `compute_passes` in 0..4. Invalid framing or bounds return -1.
- Each leaf starts with active and reactive demand `(1,1)`. The root starts
  with `(theta_R, theta_I)=(0.8,0.16)`. Branch and lateral impedances and the
  voltage, gradient, and alpha/beta recurrences follow the pinned source.
- Each pass performs one source-ordered `Compute_Tree` sweep. To bound this
  profile, every `optimize_node` call executes exactly one body of the source's
  do-while loop. That body retains the source's constraint projection,
  gradients, orthogonalization, and constrained benefit update.
- The scalar result observes the completed recurrence. For every leaf, the
  implementation adds `round_half_up(1000*P) + 2*round_half_up(1000*Q)`;
  it adds corresponding weighted terms for branch alpha/beta and lateral
  alpha/beta, then adds the exact count of leaf optimizer bodies executed.
  Here `round_half_up(x)` is `floor(x + 0.5)`. The output therefore depends on
  final leaf and network state, keeping the optimizer recurrence observable.
- The independent [oracle](../../olden_power_oracle.py) computes the bounded
  optimizer and network recurrence for generated verifier inputs. Static
  valid fixtures are limited to zero-pass cases, whose expected values follow
  directly from the initialized leaf demands and zero alpha/beta state.

## Provenance and license

The launcher compiles `build.c`, `compute.c`, and `main.c` with `-DTORONTO`.
The pinned source headers refer to `olden_v1.0/COPYRIGHT`, but that file is
absent from this repository snapshot. The repository therefore does not
provide enough evidence to infer an upstream license. These ports are written
independently from the source's documented tree model and equations.

## Language ports

| Language | Source |
| --- | --- |
| C | [c/o/olden_power.c](../../../c/o/olden_power.c) |
| C3 | [c3/o/olden_power.c3](../../../c3/o/olden_power.c3) |
| C++ | [cpp/o/olden_power.cpp](../../../cpp/o/olden_power.cpp) |
| Elisa | [elisa/o/olden_power.elisa](../../../elisa/o/olden_power.elisa) |
| Nim | [nim/o/olden_power.nim](../../../nim/o/olden_power.nim) |
| Odin | [odin/o/olden_power.odin](../../../odin/o/olden_power.odin) |
| Rust | [rust/o/olden_power.rs](../../../rust/o/olden_power.rs) |
| V | [v/o/olden_power.v](../../../v/o/olden_power.v) |
| Zig | [zig/o/olden_power.zig](../../../zig/o/olden_power.zig) |

## Pinned source files

- [`build.c`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/Olden/power/build.c)
- [`compute.c`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/Olden/power/compute.c)
- [`power.h`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/Olden/power/power.h)
- [`info.sh`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/Olden/power/info.sh)
