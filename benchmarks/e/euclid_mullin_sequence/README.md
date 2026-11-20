# Euclid–Mullin sequence

This package returns a bounded one-based term of the Euclid–Mullin sequence.
It starts with `a(1)=2`; each following term is the **least prime factor** of
one plus the product of all preceding terms.

## Contract

The `i64_array_scalar` function `euclid_mullin_sequence` accepts `[n]` for
`1<=n<=8`. It returns `-1` for null input, malformed framing, or an index
outside that range. The bounded sequence begins
`2, 3, 7, 43, 13, 53, 5, 6221671`.

The primary ports keep the prior-term product and trial-divide its successor
by ascending integers. The first divisor is prime and is the least prime
factor; if no divisor appears through the square root, the candidate itself
is prime. Products and candidates use division guards instead of squaring a
divisor. The largest candidate is 6,221,671, and all prefix products through
the eighth term fit signed 64-bit. The primary uses only scalar state, with a
64-byte workspace cap.

The independent reference sieves the bounded prime candidates through 2,494
and checks only primes in ascending order. This separates prime-candidate
generation from the primary's all-integer trial scan.

## Distinctness and sources

The local [`primorial_numbers_sequence`](../primorial_numbers_sequence/README.md)
returns products of initial prime prefixes; its Euclid-number mapping adds one
to those products. The local [`sylvester_sequence`](../sylvester_sequence/README.md)
returns each full Euclid product-plus-one value recursively. This package
instead returns the least prime factor, which can be a proper factor and can
be smaller than the prior term.

Booker and Irvine define the recurrence and give the initial terms in
[“The Euclid–Mullin Graph”](https://research-information.bris.ac.uk/files/65358793/emgraph.pdf),
*Journal of Number Theory* 165 (2016), 30–57. The sequence traces back to
Mullin's [1963 problem note](https://doi.org/10.1090/S0002-9904-1963-11017-4).
[OEIS A000945](https://oeis.org/A000945) provides the sequence cross-reference.
The RosettaCodeData popular-title index was used only to discover the task;
no task text, examples, source code, or fixtures were reused.

## Workload and inventory

[`workload.json`](workload.json) pins source-published initial terms, the
maximum supported index, and invalid frames. The primary direct-factorization
and independent prime-sieve references, static inventory, and ten source paths
are listed in [`INVENTORY.md`](INVENTORY.md). The package is prepared for root
suite integration; shared suite and catalog entries remain root-owned.

## Language ports

| Language | Source |
|---|---|
| C | [`c/e/euclid_mullin_sequence.c`](../../../c/e/euclid_mullin_sequence.c) |
| C3 | [`c3/e/euclid_mullin_sequence.c3`](../../../c3/e/euclid_mullin_sequence.c3) |
| C++ | [`cpp/e/euclid_mullin_sequence.cpp`](../../../cpp/e/euclid_mullin_sequence.cpp) |
| Elisa | [`elisa/e/euclid_mullin_sequence.elisa`](../../../elisa/e/euclid_mullin_sequence.elisa) |
| Mojo | [`mojo/e/euclid_mullin_sequence.mojo`](../../../mojo/e/euclid_mullin_sequence.mojo) |
| Nim | [`nim/e/euclid_mullin_sequence.nim`](../../../nim/e/euclid_mullin_sequence.nim) |
| Odin | [`odin/e/euclid_mullin_sequence.odin`](../../../odin/e/euclid_mullin_sequence.odin) |
| Rust | [`rust/e/euclid_mullin_sequence.rs`](../../../rust/e/euclid_mullin_sequence.rs) |
| V | [`v/e/euclid_mullin_sequence.v`](../../../v/e/euclid_mullin_sequence.v) |
| Zig | [`zig/e/euclid_mullin_sequence.zig`](../../../zig/e/euclid_mullin_sequence.zig) |
