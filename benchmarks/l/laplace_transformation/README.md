# Laplace transformation

This package ports the pinned numerical Laplace transform using bounded integer input samples and a binary64 result.

## Contract

Input is `[n, s_milli, dt_micro, f0_micro, ..., f(n-1)_micro]`, with `n` from 1 through 64 and exactly `n+3` values. The parser accepts up to one extra value for malformed-input coverage. The Laplace parameter is `s_milli / 1,000`, the time step is `dt_micro / 1,000,000`, and each sample is `f_i_micro / 1,000,000`; bounds are `s_milli` 0..1,000, `dt_micro` 1..1,000,000, and each sample -1,000,000..1,000,000.

For one sample, the result is zero, matching the trapezoid rule on a one-element vector. For more samples, the port follows NumPy's `linspace(0, (n-1)*dt, n)` construction, including its computed step and exact final endpoint, then forms `f(t_i) * exp(-s*t_i)` and accumulates the trapezoid intervals in source order using `dt * (y_i + y_(i+1)) / 2`. Invalid input returns `-1e300`. Output comparison uses absolute and relative tolerances of `1e-12`.

Pinned source: [laplace_transformation.py](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/maths/laplace_transformation.py). See [workload](workload.json) and [oracle](../../laplace_transformation_oracle.py).

| Language | Port |
|---|---|
| C | ../../../c/l/laplace_transformation.c |
| C3 | ../../../c3/l/laplace_transformation.c3 |
| C++ | ../../../cpp/l/laplace_transformation.cpp |
| Elisa | ../../../elisa/l/laplace_transformation.elisa |
| Nim | ../../../nim/l/laplace_transformation.nim |
| Odin | ../../../odin/l/laplace_transformation.odin |
| Rust | ../../../rust/l/laplace_transformation.rs |
| V | ../../../v/l/laplace_transformation.v |
| Zig | ../../../zig/l/laplace_transformation.zig |
