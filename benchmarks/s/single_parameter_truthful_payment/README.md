# Single-parameter truthful payment profile

This package covers one concrete subcase from Moshe Babaioff's *Encyclopedia of Algorithms* chapter “Truthful Mechanisms for One-Parameter Agents,” DOI [`10.1007/978-1-4939-2864-4_436`](https://doi.org/10.1007/978-1-4939-2864-4_436): the Archer–Tardos payment formula for a monotone single-parameter allocation rule.

## Bounded contract

- ABI: `i64_array_bytes_output`; input is `[bid,k,breakpoint_0,load_0,...,breakpoint_(k-1),load_(k-1)]`.
- `0<=bid<=16`, `1<=k<=8`. Breakpoints are strictly increasing integers beginning at 0 and lying in `[0,15]`; loads are integers in `[0,16]` and nonincreasing. These define a right-continuous step allocation `w(u)=load_j` on `[breakpoint_j,breakpoint_(j+1))`, with the final interval ending at 16 and `w(u)=0` for `u>=16`.
- The profile computes `P(b)=b*w(b)+∫_b^∞w(u)du` with `h_i=0`; integer breakpoints and loads make the integral exact. It returns `[w(b),P(b)]` as two little-endian signed-i64 words. Maximum input is 18 words and output is 16 bytes.
- This is only the bounded payment-characterization subcase. It does not choose an allocation rule, implement the chapter's scheduling approximation mechanisms, or cover continuous arbitrary allocation functions.

## Provenance and rights

Source attribution: Moshe Babaioff, “Truthful Mechanisms for One-Parameter Agents,” *Encyclopedia of Algorithms*, DOI `10.1007/978-1-4939-2864-4_436`; the payment identity is the Archer–Tardos characterization cited in the chapter. The chapter and summarized research remain copyrighted. This package is a clean-room implementation of that formula and copies no prose, code, or figures; no source-code license is asserted. See [`RIGHTS.md`](RIGHTS.md).

## Package files

- [`workload.json`](workload.json)
- [primary exact-area oracle](../../single_parameter_truthful_payment_oracle.py)
- [independent unit-interval verifier](../../single_parameter_truthful_payment_verifier_oracle.py)

| Language | Port |
|---|---|
| C | [`c/s/single_parameter_truthful_payment.c`](../../../c/s/single_parameter_truthful_payment.c) |
| C3 | [`c3/s/single_parameter_truthful_payment.c3`](../../../c3/s/single_parameter_truthful_payment.c3) |
| C++ | [`cpp/s/single_parameter_truthful_payment.cpp`](../../../cpp/s/single_parameter_truthful_payment.cpp) |
| Elisa | [`elisa/s/single_parameter_truthful_payment.elisa`](../../../elisa/s/single_parameter_truthful_payment.elisa) |
| Nim | [`nim/s/single_parameter_truthful_payment.nim`](../../../nim/s/single_parameter_truthful_payment.nim) |
| Odin | [`odin/s/single_parameter_truthful_payment.odin`](../../../odin/s/single_parameter_truthful_payment.odin) |
| Rust | [`rust/s/single_parameter_truthful_payment.rs`](../../../rust/s/single_parameter_truthful_payment.rs) |
| V | [`v/s/single_parameter_truthful_payment.v`](../../../v/s/single_parameter_truthful_payment.v) |
| Zig | [`zig/s/single_parameter_truthful_payment.zig`](../../../zig/s/single_parameter_truthful_payment.zig) |
