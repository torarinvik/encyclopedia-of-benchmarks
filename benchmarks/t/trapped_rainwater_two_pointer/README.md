# Trapped rainwater with two pointers

This package preserves the distinct O(1)-auxiliary-space algorithm in the pinned C++ `trapped_rainwater2.cpp` source. It advances the side with the smaller current boundary, maintains the maximum height seen from each side, and accumulates water as each index is finalized. The existing [`trapped_rainwater`](../trapped_rainwater/README.md) package uses prefix and suffix maximum arrays, so it has the same result contract but a different algorithm and space profile.

Source: [TheAlgorithms/C-Plus-Plus `trapped_rainwater2.cpp`](https://github.com/TheAlgorithms/C-Plus-Plus/blob/fdcc29b0ac2848e9d1a8d926e171cc5b39f97759/dynamic_programming/trapped_rainwater2.cpp).

## Contract

- Input is an array of 0–4,096 signed 64-bit heights.
- Heights must be between 0 and 1,000,000 inclusive.
- Return total trapped water; arrays shorter than three return 0.
- Return `-1` for invalid lengths or heights.
- The maximum total is 4,094,000,000, within the source's unsigned 32-bit result range.

The two-pointer tie rule matches the source: process the right side when left and right heights are equal.
