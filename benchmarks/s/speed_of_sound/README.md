# Speed of Sound in a Fluid

This package benchmarks the fluid calculation in the pinned [TheAlgorithms/Python source](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/physics/speed_of_sound.py). Its function `speed_of_sound_in_a_fluid(density, bulk_modulus)` returns `(bulk_modulus / density) ** 0.5`.

The `i64_array_float64` ABI accepts exactly two signed integers in this order: `[density, bulk_modulus]`. Density is bounded to 1..1,000 and bulk modulus to 1..1,000,000,000; both ranges satisfy the source's strictly positive guards. Ports divide bulk modulus by density, then raise the quotient to 0.5. Invalid lengths and values return -1e300.

The output is binary64 speed in metres per second, compared with absolute and relative tolerances of `1e-12` to allow for small differences among language math libraries. Runtime and auxiliary space are O(1).
