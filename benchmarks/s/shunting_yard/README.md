# Shunting yard expression evaluation

This benchmark ports the pinned Swift `ShuntingYard.evaluate(_:)` routine over a bounded ASCII expression grammar. It evaluates one complete binary arithmetic expression and returns one binary64 result.

## Contract

The ABI is `i64_array_float64`. Input is `[byte_count, ASCII expression bytes...]`, with 1–255 expression bytes and an exact packed length. A valid packed input has at most 256 i64 values; malformed framing returns the invalid sentinel. Literals contain one or more ASCII integer digits, optionally followed by a decimal point and one or more fractional digits. Each literal is at most 16 bytes and has a value from 0 through 1,000,000. Unary signs, exponent notation, parentheses, implicit multiplication, and non-ASCII bytes are excluded. ASCII spaces, tabs, line feeds, vertical tabs, form feeds, and carriage returns may separate tokens. Expressions contain at most 16 operands and 15 operators.

Convert integer digits left-to-right from binary64 0.0 by multiplying by 10.0 and then adding the digit. After the decimal point, start scale at binary64 0.1; for each fractional digit, add digit times scale, then divide scale by 10.0. Each operation rounds separately to binary64; fused multiply-add is disabled. The rounding mode is round-to-nearest, ties-to-even, and compilers must not reassociate these operations.

The operators are `+`, `-`, `*`, `/`, and `^`. Precedence is 3 for power, 2 for multiplication/division, and 1 for addition/subtraction. Power is right-associative; the other operators are left-associative. The source pops the most recent number as `a`, then the earlier number as `b`; it computes subtraction as `b-a`, division as `b/a`, and power as `pow(b,a)`.

The wrapper requires a complete alternating number/operator expression, rejects unparsed suffixes and malformed stack shapes, and bounds each literal to 1,000,000 and each intermediate result to finite magnitude at most 1e12. Division by zero and real-power domain errors return the invalid sentinel `-1e300`. Valid results compare with absolute and relative tolerances of 1e-12.

The pinned implementation uses Foundation `Scanner`; its default scanner skips whitespace and newlines and, with no locale set, scans nonlocalized numeric values. The benchmark restricts this behavior to ASCII whitespace and dot-decimal literals for a portable contract. See Apple's [Scanner](https://developer.apple.com/documentation/foundation/scanner), [charactersToBeSkipped](https://developer.apple.com/documentation/foundation/scanner/characterstobeskipped), and [locale](https://developer.apple.com/documentation/foundation/scanner/locale) documentation.

## Pinned source

[TheAlgorithms/Swift `shunting_yard.swift`](https://github.com/TheAlgorithms/Swift/blob/2c9eb8b85dee6db46cb33452c0b904eb7d7d179c/algorithms/parsing/shunting_yard/shunting_yard.swift), commit `2c9eb8b85dee6db46cb33452c0b904eb7d7d179c`, method `ShuntingYard.evaluate(_:)`.

The separate upstream C candidate is excluded because its precedence-stack implementation is incorrect. The local C port implements the valid Swift contract.

## Workload

Cases and expected scalar outputs are in [workload.json](workload.json). The independent oracle is [shunting_yard_oracle.py](../../shunting_yard_oracle.py).

## Ports

| Language | Source |
| --- | --- |
| C | [`c/s/shunting_yard.c`](../../../c/s/shunting_yard.c) |
| C3 | [`c3/s/shunting_yard.c3`](../../../c3/s/shunting_yard.c3) |
| C++ | [`cpp/s/shunting_yard.cpp`](../../../cpp/s/shunting_yard.cpp) |
| Elisa | [`elisa/p/shunting_yard.elisa`](../../../elisa/p/shunting_yard.elisa) |
| Nim | [`nim/p/shunting_yard.nim`](../../../nim/p/shunting_yard.nim) |
| Odin | [`odin/p/shunting_yard.odin`](../../../odin/p/shunting_yard.odin) |
| Rust | [`rust/p/shunting_yard.rs`](../../../rust/p/shunting_yard.rs) |
| V | [`v/p/shunting_yard.v`](../../../v/p/shunting_yard.v) |
| Zig | [`zig/p/shunting_yard.zig`](../../../zig/p/shunting_yard.zig) |
