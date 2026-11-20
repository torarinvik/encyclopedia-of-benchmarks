# Binary divisibility by three with a streaming DFA

This profile decides whether an MSB-first binary digit stream represents a
multiple of three. Its native implementation keeps only the current remainder
state; it never constructs the integer represented by the input.

## Contract

- ABI: `i64_array_bytes_output`.
- Input is `[L, bit_0, ..., bit_(L-1)]`, with `1 <= L <= 4096` and each bit
  equal to `0` or `1`. Bits are most-significant first. Leading zeroes count
  toward `L` and are accepted.
- A valid call writes exactly one raw byte: `1` for divisible by three and `0`
  otherwise. The return value is the byte count, `1`.
- A null input, invalid length or framing, or invalid bit returns `-1` before
  checking output storage. A null output or capacity below one returns `-2`.
  Errors write no bytes.
- The primary method starts at remainder zero and scans each bit with
  `r = (2*r + bit) mod 3`. It runs in `O(L)` time with `O(1)` auxiliary
  state. The accepted maximum input frame has 4097 signed 64-bit words; one
  extra word is parseable so trailing data is rejected explicitly.
- The bounded auxiliary-workspace allowance is 64 bytes for local scan and
  remainder bookkeeping; input and output buffers are excluded.

## Distinction and references

[`binary_to_decimal`](../binary_to_decimal/README.md) materializes a signed
64-bit number and caps its bit sequence at 63 digits. This DFA accepts up to
4096 digits without a larger integer or intermediate allocation.
[`is_divisible`](../../i/is_divisible/README.md) checks numeric scalar operands
with `%`; it does not consume a bit stream. Both answer related divisibility
questions, but they exercise different input representations and kernels.

The independent reference uses the identity `2 == -1 (mod 3)` and tests the
alternating-sign sum of the bits, not the DFA transition. The automaton method
is described in Dexter Kozen's [Cornell CS 4810 lecture notes](https://www.cs.cornell.edu/kozen/Papers/481.pdf).
The discovery lead was the public Codewars title “Binary multiple of 3” in its
[Algorithms and Number Theory catalog](https://www.codewars.com/kata?tags=Algorithms%2CNumber+Theory);
the title/tag listing was used for discovery only.

[`workload.json`](workload.json) pins short examples, leading zeroes, a
64-bit all-ones stream, malformed frames, and output-buffer errors.
[`primary_oracle.py`](primary_oracle.py) and
[`independent_oracle.py`](independent_oracle.py) implement the two reference
methods. `verify_workload.py` contains static fixture checks, and
`check_inventory.py` checks package files and port presence. These checkers
have not been run.

## Implementations

| Language | Source |
| --- | --- |
| C | [c/b/binary_divisibility_by_three_dfa.c](../../../c/b/binary_divisibility_by_three_dfa.c) |
| C3 | [c3/b/binary_divisibility_by_three_dfa.c3](../../../c3/b/binary_divisibility_by_three_dfa.c3) |
| C++ | [cpp/b/binary_divisibility_by_three_dfa.cpp](../../../cpp/b/binary_divisibility_by_three_dfa.cpp) |
| Elisa | [elisa/b/binary_divisibility_by_three_dfa.elisa](../../../elisa/b/binary_divisibility_by_three_dfa.elisa) |
| Mojo | [mojo/b/binary_divisibility_by_three_dfa.mojo](../../../mojo/b/binary_divisibility_by_three_dfa.mojo) |
| Nim | [nim/b/binary_divisibility_by_three_dfa.nim](../../../nim/b/binary_divisibility_by_three_dfa.nim) |
| Odin | [odin/b/binary_divisibility_by_three_dfa.odin](../../../odin/b/binary_divisibility_by_three_dfa.odin) |
| Rust | [rust/b/binary_divisibility_by_three_dfa.rs](../../../rust/b/binary_divisibility_by_three_dfa.rs) |
| V | [v/b/binary_divisibility_by_three_dfa.v](../../../v/b/binary_divisibility_by_three_dfa.v) |
| Zig | [zig/b/binary_divisibility_by_three_dfa.zig](../../../zig/b/binary_divisibility_by_three_dfa.zig) |

The byte-output runner/verifier and root catalog now register this profile. No
checkers, programs, builds, compilers, tests, or benchmarks have been run.
