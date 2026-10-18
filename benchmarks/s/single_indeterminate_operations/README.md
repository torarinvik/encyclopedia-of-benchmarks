# Single-indeterminate polynomial operations

This benchmark covers the six numeric operations on the pinned Python `Polynomial` class: addition, subtraction, multiplication, evaluation, derivative, and integral. String formatting, representation, and equality are outside the measured operation.

## Contract

The input is a float64 slice with an integer-valued operation selector and integer-valued polynomial degrees. Coefficients are listed from the constant term upward. Selectors are `0` add, `1` subtract, `2` multiply, `3` evaluate, `4` derivative, and `5` integral.

For add, subtract, and multiply, the encoding is `[operation, degree_a, a0, ..., degree_b, b0, ...]`. For evaluation, it is `[3, degree, c0, ..., c_degree, x]`. For derivative, it is `[4, degree, c0, ..., c_degree]`. For integral, it is `[5, degree, c0, ..., c_degree, constant]`.

Degrees range from 0 through 8, coefficients and the integral constant range from -10 through 10, and the evaluation point ranges from -2 through 2. The maximum valid input length is 21 float64 elements; 22 is the maximum parseable length for an extra-value framing probe. All inputs and calculated outputs must be finite.

Add, subtract, and multiply return the resulting low-degree-first coefficient vector. The source does not trim high-degree zero coefficients; the result retains its degree-derived length. Evaluation returns one value and accumulates terms in ascending degree order using `coefficient[i] * x**i`. The derivative returns `degree` coefficients, so a constant polynomial returns an empty vector (result count zero). The integral returns the supplied constant followed by each coefficient divided by its new power. Maximum output length is 17 values.

Subtraction follows the source expression `self + other * Polynomial(0, [-1])`; multiplication uses nested loops with the left coefficient index outermost and accumulates each product into its result slot. Addition preserves the source's degree comparison and base-vector choice. Compare float64 outputs with absolute and relative tolerances of `1e-12`.

Malformed framing, an invalid selector or degree, nonfinite values, or values outside the declared bounds returns `-1` before output checks. A valid operation with a null output pointer returns `-2`, including a zero-length derivative. Insufficient capacity returns `-2`; a non-null output pointer with capacity zero succeeds for that zero-length derivative. Errors write no output values.

The independent oracle is [`../../single_indeterminate_operations_oracle.py`](../../single_indeterminate_operations_oracle.py). The workload includes all six operations, unequal degrees, retained zero coefficients, maximum-degree multiplication, malformed framing, and output-capacity edges.

## Pinned source

- Python [`single_indeterminate_operations.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/maths/polynomials/single_indeterminate_operations.py), specifically `Polynomial.__add__`, `Polynomial.__sub__`, `Polynomial.__mul__`, `Polynomial.evaluate`, `Polynomial.derivative`, and `Polynomial.integral`.

## Language ports

| Language | Port |
|---|---|
| C | [`c/s/single_indeterminate_operations.c`](../../../c/s/single_indeterminate_operations.c) |
| C3 | [`c3/s/single_indeterminate_operations.c3`](../../../c3/s/single_indeterminate_operations.c3) |
| C++ | [`cpp/s/single_indeterminate_operations.cpp`](../../../cpp/s/single_indeterminate_operations.cpp) |
| Elisa | [`elisa/s/single_indeterminate_operations.elisa`](../../../elisa/s/single_indeterminate_operations.elisa) |
| Nim | [`nim/s/single_indeterminate_operations.nim`](../../../nim/s/single_indeterminate_operations.nim) |
| Odin | [`odin/s/single_indeterminate_operations.odin`](../../../odin/s/single_indeterminate_operations.odin) |
| Rust | [`rust/s/single_indeterminate_operations.rs`](../../../rust/s/single_indeterminate_operations.rs) |
| V | [`v/s/single_indeterminate_operations.v`](../../../v/s/single_indeterminate_operations.v) |
| Zig | [`zig/s/single_indeterminate_operations.zig`](../../../zig/s/single_indeterminate_operations.zig) |
