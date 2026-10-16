# Reduced rational addition

This benchmark follows the pinned Lua fraction library's addition operator. Each input is `[numerator_a, denominator_a, numerator_b, denominator_b]`; numerators are in `[-10000,10000]`, denominators are nonzero and in `[-1000,1000]`. It extends both fractions to the source's gcd-derived common denominator, adds the numerators, then applies the constructor's reduction and positive-denominator normalization. The result is two little-endian signed 64-bit integers `[numerator, denominator]`. Invalid inputs return -1 and insufficient output capacity returns -2. Runtime oracle: `fraction_oracle.py`.

The larger Lua module also implements construction from several formats, comparison, powers, modulo, and base conversion; this bounded contract measures its reduced arithmetic path without its Lua metatable API.
