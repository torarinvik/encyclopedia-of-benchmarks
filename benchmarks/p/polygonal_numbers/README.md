# Polygonal Numbers

This benchmark computes the `num`th s-gonal number using the pinned Python formula. It generalizes fixed-side standard polygonal terms such as triangular, hexagonal, and heptagonal numbers by accepting the side count as input; central polygonal numbers are a distinct sequence.

## Contract

- The signed 64-bit input is exactly `[num, sides]`.
- `num` is from 0 through 100,000,000, inclusive. `sides` is from 3 through 64, inclusive.
- The result is `((sides - 2) * num * num - (sides - 4) * num) // 2`, preserving the source's multiplication, subtraction, and final division order. The numerator is even throughout this domain.
- The maximum intermediate product is 620,000,000,000,000,000, within signed 64-bit range.
- Wrong packed length or out-of-domain inputs return `-1`. The source raises `ValueError` for a negative index or fewer than three sides; these map to the benchmark invalid sentinel.
- `num = 0` returns 0, matching the source.

The side counts 3, 6, and 7 give triangular, hexagonal, and heptagonal numbers respectively. The broader contract is distinct from the existing fixed-side term and sequence benchmarks.

## Workload

[`workload.json`](workload.json) covers source examples, several side counts, zero and boundary values, the largest supported term, and invalid packed inputs.

The shared scalar-array runner validates each case against the bounded closed-form integer formula.

## Reviewed source

- [Python `polygonal_numbers.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/maths/special_numbers/polygonal_numbers.py) — direct closed-form `polygonal_num(num, sides)` implementation.

## Implementations

The nine portable ports use the shared `i64_array_scalar` ABI. Their source files are in the `p` folder for each language.
