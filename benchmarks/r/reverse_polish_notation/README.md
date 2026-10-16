# Reverse Polish notation

This package ports the pinned JavaScript ReversePolishNotation evaluator.

## Contract

- Input is a raw signed i64 array of ASCII code values. It represents an expression with at most 255 bytes and at most 63 tokens. Tokens are separated by exactly one ASCII space.
- A number token is an optional plus or minus sign followed by decimal digits, with magnitude at most 1,000,000. Operators are plus, minus, multiply, and divide.
- The source pops the top value as a and the next value as b. Addition and multiplication return a+b and a*b; subtraction returns a-b; division returns b/a.
- A valid expression leaves exactly one stack value. Division by zero, malformed tokens, stack underflow, extra final values, non-finite results, or an intermediate magnitude above 1e200 return -1e300.
- The result is a float64. The bounded integer-token contract is a deliberate adapter subset of the source's permissive parseFloat input.

## Workload and oracle

[workload.json](workload.json) covers arithmetic operators, source operand order, signed and zero-padded integers, nested expressions, maximum text and token counts, division by zero, and malformed expressions. The independent oracle is [reverse_polish_notation_oracle.py](../../reverse_polish_notation_oracle.py).

Pinned source: [TheAlgorithms/JavaScript ReversePolishNotation.js](https://github.com/TheAlgorithms/JavaScript/blob/5c39e87a9a31f279c60f830ad74a845e4788a517/Maths/ReversePolishNotation.js).

## Build and record

Build the selected ABI with:

    python3 benchmarks/build_abi.py --family i64_array_float64 --algorithm reverse_polish_notation --language rust

Record the workload with:

    python3 benchmarks/run_i64_array_float64.py --algorithm reverse_polish_notation

## Implementations

| Language | Source |
| --- | --- |
| C | [c/r/reverse_polish_notation.c](../../../c/r/reverse_polish_notation.c) |
| C3 | [c3/r/reverse_polish_notation.c3](../../../c3/r/reverse_polish_notation.c3) |
| C++ | [cpp/r/reverse_polish_notation.cpp](../../../cpp/r/reverse_polish_notation.cpp) |
| Elisa | [elisa/r/reverse_polish_notation.elisa](../../../elisa/r/reverse_polish_notation.elisa) |
| Nim | [nim/r/reverse_polish_notation.nim](../../../nim/r/reverse_polish_notation.nim) |
| Odin | [odin/r/reverse_polish_notation.odin](../../../odin/r/reverse_polish_notation.odin) |
| Rust | [rust/r/reverse_polish_notation.rs](../../../rust/r/reverse_polish_notation.rs) |
| V | [v/r/reverse_polish_notation.v](../../../v/r/reverse_polish_notation.v) |
| Zig | [zig/r/reverse_polish_notation.zig](../../../zig/r/reverse_polish_notation.zig) |
