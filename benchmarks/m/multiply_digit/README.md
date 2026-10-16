# multiply_digit

`multiply_digit` multiplies two signed integer operands. The source reference is Solidity's `multiplyDigit.sol`, pinned at commit [`08cba51fb38e276062b0c9791d7e0ee494ffa903`](https://github.com/TheAlgorithms/Solidity/blob/08cba51fb38e276062b0c9791d7e0ee494ffa903/src/Maths/multiplyDigit.sol). Its contract stores two `int128` values through setters and returns their product. Solidity 0.8 checks multiplication overflow and reverts.

The benchmark normalizes the setter sequence to one deterministic two element input `[first, second]`. Both values are restricted to `[-1,000,000,000, 1,000,000,000]`, so the product always fits signed 64-bit output. The scalar result is exactly `first * second`; invalid inputs return `INT64_MIN`, which cannot collide with a valid product. Inputs must contain exactly two signed 64-bit integers.

Cases cover signs, zero, maximum-magnitude products, malformed lengths, and operands outside the benchmark domain. The package uses the `i64_array_scalar` ABI.
