# Monte Carlo option price

This benchmark replays the pinned R `monte_carlo_option_price` function with supplied standard-normal variates. It keeps the function's outer simulation loop, its geometric Brownian motion path construction, the terminal European call payoff, the arithmetic mean, and one final discount factor. The RNG is replaced with explicit input so each implementation sees the same draws.

The ABI is `float64_slice_io`: one input slice contains the option parameters and all standard-normal variates, and one output element contains the discounted option price.

## Contract

Input is `[S0, K, r, sigma, T, n, num_simulations, z00, z01, ..., z(m-1)(n-1)]`, where `m` is `num_simulations`. The variates are laid out by simulation and then by time step: simulation 0 consumes the first `n` values, simulation 1 consumes the next `n`, and so on. The input length is exactly `7 + n*m`, with at most 519 valid values and 520 parseable values for an extra-value rejection case.

`S0` is in `[1, 1000]`, `K` in `[0, 2000]`, `r` in `[-0.25, 0.25]`, and `sigma` in `[0, 0.5]`. `T` is one of `{0.25, 0.5, 1, 2}`, `n` one of `{1, 2, 4, 8, 16}`, and `num_simulations` is from 1 through 32. Every supplied normal variate is finite and in `[-3, 3]`. The selected maturities and step counts make `dt=T/n` an exact binary fraction, so the source's `seq(0, T, by=dt)` has exactly `n+1` points ending at `T`.

For each simulation, start with `W[0]=0`; for each step in order, set `W[j+1] = W[j] + sqrt(dt)*z[j]`. The source constructs `S[j] = S0*exp((r - 0.5*sigma^2)*t[j] + sigma*W[j])` for `j=0..n`; only `S[n]` is used. Store `max(S[n]-K, 0)`, preserving the outer simulation order. Return the sum of those payoffs divided by `num_simulations`, then multiplied by `exp(-r*T)`. The output is one finite float64; compare with absolute and relative tolerances of `1e-12`.

The random-number generator and the top-level 10,000-simulation demo are outside this contract. Path generation remains part of the option-price operation; no separate path-only result is exposed. The R script's `quantmod` import is unused by these functions. Malformed input or values outside the declared domain return `-1` before output checks. A null output pointer or capacity below one element returns `-2`; errors write no output values.

The workload includes deterministic in-the-money and out-of-the-money payoffs, stochastic paths with mixed payoffs, negative and positive rates, zero volatility, maximum step and simulation counts, malformed frames, and output-buffer edge cases. The independent oracle is [`../../monte_carlo_simulation_oracle.py`](../../monte_carlo_simulation_oracle.py).

## Pinned source

- TheAlgorithms/R [`monte_carlo_simulation.r`](https://github.com/TheAlgorithms/R/blob/f65344fabeea0ae33c1ca321af709447c1a8a4c2/quantitative_finance/monte_carlo_simulation.r), specifically `simulate_stock_prices` and `monte_carlo_option_price`.

## Language ports

| Language | Port |
|---|---|
| C | [`c/m/monte_carlo_simulation.c`](../../../c/m/monte_carlo_simulation.c) |
| C3 | [`c3/m/monte_carlo_simulation.c3`](../../../c3/m/monte_carlo_simulation.c3) |
| C++ | [`cpp/m/monte_carlo_simulation.cpp`](../../../cpp/m/monte_carlo_simulation.cpp) |
| Elisa | [`elisa/m/monte_carlo_simulation.elisa`](../../../elisa/m/monte_carlo_simulation.elisa) |
| Nim | [`nim/m/monte_carlo_simulation.nim`](../../../nim/m/monte_carlo_simulation.nim) |
| Odin | [`odin/m/monte_carlo_simulation.odin`](../../../odin/m/monte_carlo_simulation.odin) |
| Rust | [`rust/m/monte_carlo_simulation.rs`](../../../rust/m/monte_carlo_simulation.rs) |
| V | [`v/m/monte_carlo_simulation.v`](../../../v/m/monte_carlo_simulation.v) |
| Zig | [`zig/m/monte_carlo_simulation.zig`](../../../zig/m/monte_carlo_simulation.zig) |
