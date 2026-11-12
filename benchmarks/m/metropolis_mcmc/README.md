# Metropolis Markov-chain sampling

This package implements the Metropolis accept/reject transition for a discrete target distribution. Given a symmetric proposal tape, it accepts every transition to equal or lower energy and accepts an uphill transition with probability `exp(-delta_energy / temperature)`. The output is the state trace, including the initial state and one state after every proposal.

The workload supplies proposal states and uniform variates so each language processes the same deterministic chain. Each transition consumes its uniform variate even when the proposal is downhill. The bounded input uses at most 8 states and 64 steps, energies in `[-1,000,000, 1,000,000]`, and temperature in `[0.001, 1,000]`. Validation and transitions take `O(state_count + step_count)` time; auxiliary space is `O(1)` beyond the caller-owned input and output arrays.

This is a sampling algorithm: it uses one fixed temperature and returns a Markov-chain trace. It is distinct from [`simulated_annealing`](../simulated_annealing/README.md), which changes temperature to search for a low-scoring solution and returns an optimization result.

The algorithm description is based on the original [Metropolis et al. paper](https://doi.org/10.1063/1.1699114) and the [Algorithm Archive overview](https://www.algorithm-archive.org/contents/metropolis/metropolis.html). The oracle uses direct host `exp` evaluation and does not reuse any language port.

| Language | Source |
| --- | --- |
| C | [`c/m/metropolis_mcmc.c`](../../../c/m/metropolis_mcmc.c) |
| C3 | [`c3/m/metropolis_mcmc.c3`](../../../c3/m/metropolis_mcmc.c3) |
| C++ | [`cpp/m/metropolis_mcmc.cpp`](../../../cpp/m/metropolis_mcmc.cpp) |
| Elisa | [`elisa/m/metropolis_mcmc.elisa`](../../../elisa/m/metropolis_mcmc.elisa) |
| Mojo | [`mojo/m/metropolis_mcmc.mojo`](../../../mojo/m/metropolis_mcmc.mojo) |
| Nim | [`nim/m/metropolis_mcmc.nim`](../../../nim/m/metropolis_mcmc.nim) |
| Odin | [`odin/m/metropolis_mcmc.odin`](../../../odin/m/metropolis_mcmc.odin) |
| Rust | [`rust/m/metropolis_mcmc.rs`](../../../rust/m/metropolis_mcmc.rs) |
| V | [`v/m/metropolis_mcmc.v`](../../../v/m/metropolis_mcmc.v) |
| Zig | [`zig/m/metropolis_mcmc.zig`](../../../zig/m/metropolis_mcmc.zig) |
