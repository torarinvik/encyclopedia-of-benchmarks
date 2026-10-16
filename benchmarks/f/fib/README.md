# Shifted Fibonacci (`fib`)

This benchmark implements the pinned MATLAB-Octave `fib` function, which uses a shifted zero-based convention: `fib(0)=1`, `fib(1)=2`, and `fib(n)=F(n+2)` for the standard Fibonacci sequence `F(0)=0`, `F(1)=1`. The source requires nonnegative inputs. The benchmark accepts `0..90`, where outputs fit signed 64-bit integers, and returns `-1` outside that range.

The ABI is a signed 64-bit scalar function exported as `fib`. Implementations use an iterative two-value recurrence in O(n) time and O(1) space. The final supported value is `fib(90)=7540113804746346429`; `fib(91)` would overflow. [`workload.json`](workload.json) records zero, small, representative, maximum, negative, and out-of-range inputs. `fib_oracle.py` provides an independent fast-doubling oracle.

Build and record with `python3 benchmarks/build_scalar.py --algorithm fib --language rust` and `python3 benchmarks/run_scalar.py --algorithm fib --language rust` using the generated build manifest as described by the scalar runner. The shared scalar verifier supports all nine language ports.

## Implementations

Portable implementations are in `c/f/fib.c`, `c3/f/fib.c3`, `cpp/f/fib.cpp`, `elisa/f/fib.elisa`, `nim/f/fib.nim`, `odin/f/fib.odin`, `rust/f/fib.rs`, `v/f/fib.v`, and `zig/f/fib.zig`.

## Upstream reference

- [MATLAB-Octave `fib.m`](https://github.com/TheAlgorithms/MATLAB-Octave/blob/e150b77ad256de46c1ce3815c3d7945ac4fc28dc/project-euler/Problem2/fib.m) initializes the sequence to 1 and 2 and advances n times.
