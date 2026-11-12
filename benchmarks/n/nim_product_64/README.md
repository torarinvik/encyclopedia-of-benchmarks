# 64-bit Nim Product

Compute the nim product of two unsigned 64-bit integers. The local package preserves the full official input and output range by passing each operand as two 32-bit limbs and writing the 64-bit answer as eight little-endian bytes.

## Contract

The `i64_array_bytes_output` ABI accepts exactly `[A_low, A_high, B_low, B_high]`, where each limb is in `[0, 2^32-1]`. Each pair of limbs encodes one unsigned value as `low + high * 2^32`. A valid call writes exactly eight bytes: the nim product in little-endian order and returns `8`. Invalid input returns `-1`; a null output buffer or capacity below eight returns `-2`.

This follows the [Library Checker Nim Product task](https://judge.yosupo.jp/problem/nim_product_64), which asks for `A ⊗ B` on `0 <= A,B < 2^64`. Its recursive definition uses nim-sum (XOR) and mex. The ports use the equivalent field-extension recurrence: at width `w`, split each value into two `w/2`-bit parts around `α = 2^(w/2)`, using `α² = α ⊕ 2^(w/2-1)`, then combine recursive products with Karatsuba's identity. The constant-field product is evaluated recursively as well. The recursion reaches the one-bit field where multiplication is AND. This takes `O(w^2)` bit operations and `O(log w)` call-stack space.

The [workload](workload.json) includes small nimber identities, high-bit unsigned values, malformed limbs, and output-capacity handling. The oracle uses Python arbitrary-precision integers and the direct four-product field recurrence, independent of the ports' Karatsuba reduction.

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/n/nim_product_64.c`](../../../c/n/nim_product_64.c) |
| C3 | [`c3/n/nim_product_64.c3`](../../../c3/n/nim_product_64.c3) |
| C++ | [`cpp/n/nim_product_64.cpp`](../../../cpp/n/nim_product_64.cpp) |
| Elisa | [`elisa/n/nim_product_64.elisa`](../../../elisa/n/nim_product_64.elisa) |
| Mojo | [`mojo/n/nim_product_64.mojo`](../../../mojo/n/nim_product_64.mojo) |
| Nim | [`nim/n/nim_product_64.nim`](../../../nim/n/nim_product_64.nim) |
| Odin | [`odin/n/nim_product_64.odin`](../../../odin/n/nim_product_64.odin) |
| Rust | [`rust/n/nim_product_64.rs`](../../../rust/n/nim_product_64.rs) |
| V | [`v/n/nim_product_64.v`](../../../v/n/nim_product_64.v) |
| Zig | [`zig/n/nim_product_64.zig`](../../../zig/n/nim_product_64.zig) |
