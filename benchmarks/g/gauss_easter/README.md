# Gauss Easter

Compute the date returned by the pinned Python Gauss Easter algorithm. The
benchmark preserves the source's floating-point `/ 4` operations: their
quarter-day values affect some century years, so the ports carry those values
as exact quarter units.

## Contract

Input is a signed 64-bit year from 1 through 9,999, the range accepted by
Python's `datetime`. Valid results encode the source's UTC date as
`YYYYMMDD`; invalid years return `-1`. The source's exceptional `days_to_add`
cases for April 18 and 19 are retained. This date encoding preserves the
returned year, month, and day while making the value portable across the
benchmark's scalar ABI.

The source uses `leap_day_inhibits / 4`, which is Python true division. The
quarter-unit representation in the ports preserves that behavior exactly over
the bounded year range rather than silently replacing it with integer
division.

## Source and workload

Pinned source: [TheAlgorithms/Python `gauss_easter.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/other/gauss_easter.py) at commit `e1a2a8b016001309a73d5fec4818c35cca139795`.

[`workload.json`](workload.json) covers known examples, year and century
boundaries, the datetime limits, and invalid signed 64-bit inputs. The
independent source-shaped oracle is [`gauss_easter_oracle.py`](../../gauss_easter_oracle.py).

## Implementations

| Language | Source |
| --- | --- |
| C | [c/g/gauss_easter.c](../../../c/g/gauss_easter.c) |
| C3 | [c3/g/gauss_easter.c3](../../../c3/g/gauss_easter.c3) |
| C++ | [cpp/g/gauss_easter.cpp](../../../cpp/g/gauss_easter.cpp) |
| Elisa | [elisa/g/gauss_easter.elisa](../../../elisa/g/gauss_easter.elisa) |
| Nim | [nim/g/gauss_easter.nim](../../../nim/g/gauss_easter.nim) |
| Odin | [odin/g/gauss_easter.odin](../../../odin/g/gauss_easter.odin) |
| Rust | [rust/g/gauss_easter.rs](../../../rust/g/gauss_easter.rs) |
| V | [v/g/gauss_easter.v](../../../v/g/gauss_easter.v) |
| Zig | [zig/g/gauss_easter.zig](../../../zig/g/gauss_easter.zig) |

## Verification

Run `python3 benchmarks/verify_scalar.py --algorithms gauss_easter` to check
the registered ports against the independent oracle.
