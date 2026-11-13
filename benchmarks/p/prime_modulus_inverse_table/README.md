# Prime-modulus inverse table

Input is `[Q, a_0, ..., a_(Q-1)]`, where `0 <= Q <= 32` and each operand is in `1..256`. The fixed modulus is `1,000,000,007`. The function emits one little-endian unsigned 32-bit inverse per operand and returns the byte count. Malformed input returns `-1`; a null or short output buffer for a nonempty result returns `-2`. An empty batch returns zero and accepts a null output buffer.

The algorithm builds `inv[1] = 1` and `inv[i] = m - (m / i) * inv[m % i] % m` through the largest operand, then looks up the requested entries. Its time is `O(max(a) + Q)` and its table uses `O(max(a))` space. The independent oracle uses extended Euclid for each operand. The recurrence is described by [CP-Algorithms](https://cp-algorithms.com/algebra/module-inverse.html#finding-the-modular-inverse-for-prime-moduli-using-euclidean-division); implementations are independently written from the algorithm description.

Ten language ports, a bounded workload, and byte-output suite registration are included. The ports and fixtures have not been executed during the current profiling period.
