# Deterministic MDP value iteration

This package profiles the chapter's Bellman value-iteration recurrence from
“Reinforcement Learning,” *Encyclopedia of Algorithms*, DOI
[`10.1007/978-1-4939-2864-4_341`](https://doi.org/10.1007/978-1-4939-2864-4_341).
It uses the deterministic-transition subclass of a finite discounted MDP and
performs exactly the supplied number of synchronous sweeps from the zero value
function.

Input is `[S,A,H,p,q,(reward,next_state)*S*A]`, with `1<=S<=4`, `1<=A<=3`,
`1<=H<=8`, discount `gamma=p/q` where `0<=p<q<=4`, integer rewards in
`[-100,100]`, and one deterministic next state for every state-action pair.
At each sweep, each state's new value is
`max_a(reward(s,a)+gamma*V_old(next(s,a)))`. The lowest action index wins a
tie in the final Bellman maximization.

All values are represented exactly as integers scaled by `q^H`; each port
returns that scale, the final scaled value for every state, and the greedy
action index for every state. The profile is a finite-horizon sequence of
Bellman sweeps. It does not claim convergence, stopping at an error tolerance,
stochastic transition support, Q-learning behavior, or the chapter's
underspecified Rmax exploration threshold.

Output is `[q^H,scaled_values[S],greedy_actions[S]]` as little-endian signed
i64 values (maximum 72 bytes). Malformed input returns `-1`; null output or
insufficient capacity returns `-2` without writing. The primary oracle uses
integer fixed-scale updates; the independent verifier evaluates the same
finite recurrence with exact rational fractions.

| Language | Port |
|---|---|
| C | `c/m/mdp_value_iteration_deterministic.c` |
| C3 | `c3/m/mdp_value_iteration_deterministic.c3` |
| C++ | `cpp/m/mdp_value_iteration_deterministic.cpp` |
| Elisa | `elisa/m/mdp_value_iteration_deterministic.elisa` |
| Nim | `nim/m/mdp_value_iteration_deterministic.nim` |
| Odin | `odin/m/mdp_value_iteration_deterministic.odin` |
| Rust | `rust/m/mdp_value_iteration_deterministic.rs` |
| V | `v/m/mdp_value_iteration_deterministic.v` |
| Zig | `zig/m/mdp_value_iteration_deterministic.zig` |
