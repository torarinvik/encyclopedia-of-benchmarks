# Chernick Carmichael least multiplier

For `3 <= n <= 9`, find the least admissible multiplier `m` for which all
factors in Chernick's universal form are prime:

`(6m+1)(12m+1) product(i=1..n-2)(9m*2^i+1)`.

The input is `[n]`; the result is `m`, or `-1` for an invalid input. For
`n > 4`, the theorem requires `m` to be divisible by `2^(n-4)`. For `n > 5`,
the factor coefficients `9*2^i` include every nonzero residue modulo 5, so an
`m` not divisible by 5 makes at least one factor composite. The search therefore
advances by that necessary multiplier step and is bounded at 950,560. It returns
the multiplier instead of constructing the Carmichael number, whose product
exceeds signed 64-bit range for the larger factor counts.

Primary primality checks use trial division. The independent reference builds
a sieve through the square root of the largest possible factor and searches
the admissible multiplier set independently. Search time is bounded by the
finite multiplier progression and the factor count; scratch space is `O(n)`.

This is related to but distinct from [`three_prime_carmichael_enumerator`](../three_prime_carmichael_enumerator/README.md): that profile generates general three-prime Carmichael triples, while this profile searches the restricted Chernick family for the least multiplier at each factor count. Both differ from [`carmichael_number`](../carmichael_number/README.md), which classifies a supplied integer.

The [Rosetta Code task](https://rosettagit.org/tasks/chernicks-carmichael-numbers/)
and [Chernick's original paper](https://www.ams.org/journals/bull/1939-45-04/S0002-9904-1939-06953-X/S0002-9904-1939-06953-X.pdf)
are mathematical references only. The contract, code, reference algorithms,
and fixtures are independently authored; no task solution code or prose is
reused.

| Language | Port |
|---|---|
| C | [c/c/chernick_carmichael_least_multiplier.c](../../../c/c/chernick_carmichael_least_multiplier.c) |
| C3 | [c3/c/chernick_carmichael_least_multiplier.c3](../../../c3/c/chernick_carmichael_least_multiplier.c3) |
| C++ | [cpp/c/chernick_carmichael_least_multiplier.cpp](../../../cpp/c/chernick_carmichael_least_multiplier.cpp) |
| Elisa | [elisa/c/chernick_carmichael_least_multiplier.elisa](../../../elisa/c/chernick_carmichael_least_multiplier.elisa) |
| Mojo | [mojo/c/chernick_carmichael_least_multiplier.mojo](../../../mojo/c/chernick_carmichael_least_multiplier.mojo) |
| Nim | [nim/c/chernick_carmichael_least_multiplier.nim](../../../nim/c/chernick_carmichael_least_multiplier.nim) |
| Odin | [odin/c/chernick_carmichael_least_multiplier.odin](../../../odin/c/chernick_carmichael_least_multiplier.odin) |
| Rust | [rust/c/chernick_carmichael_least_multiplier.rs](../../../rust/c/chernick_carmichael_least_multiplier.rs) |
| V | [v/c/chernick_carmichael_least_multiplier.v](../../../v/c/chernick_carmichael_least_multiplier.v) |
| Zig | [zig/c/chernick_carmichael_least_multiplier.zig](../../../zig/c/chernick_carmichael_least_multiplier.zig) |
