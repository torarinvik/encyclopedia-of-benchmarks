# Exact deterministic MDP policy iteration

This package implements the policy iteration method described in Chapter 341,
“Reinforcement Learning,” Section “Policy Iteration,” of the *Encyclopedia of
Algorithms*. It starts from a deterministic stationary policy, exactly
evaluates that policy, then greedily improves it until the policy is stable.

## Contract

The exported `mdp_policy_iteration` function uses the
`i64_array_bytes_output` ABI. Input is
`[state_count, action_count, discount_numerator, discount_denominator,
(reward,next_state)*state_count*action_count]`, in state-major then
action-major order.

- `1 <= state_count <= 4`; `1 <= action_count <= 3`.
- Discount is `p/q`, with `0 <= p < q <= 4`.
- Rewards are integers in `[-20,20]`; each next state is in
  `0..state_count-1`.
- The input length is exactly `4 + 2*state_count*action_count`, at most 28
  signed 64-bit values.

The initial policy selects action 0 in every state. Policy evaluation solves
the fixed-policy discounted equations exactly as rational numbers. Since each
state-action pair has one deterministic successor, evaluation follows each
functional-graph path, solves its eventual cycle as a finite geometric sum,
then propagates values back along the path. Policy improvement chooses the
action maximizing `reward + (p/q)*V(next_state)`; exact ties choose the lowest
action index. The algorithm stops when no state changes action.

Output is `[state_count, policy[state_count],
(value_numerator,value_denominator)*state_count]` as little-endian signed
64-bit words. Each fraction is reduced and each denominator is positive. The
result is the number of bytes written, up to 104 bytes. Invalid input returns
`-1`; null output or insufficient capacity returns `-2`; errors do not write
output. Workspace is bounded to 4,096 bytes. At most `3^4=81` policies exist,
so exact policy iteration terminates within a finite bounded search space.

## Distinction and source

The local `mdp_value_iteration_deterministic` profile performs exactly a
caller-supplied number of synchronous Bellman sweeps from zero. This package
instead evaluates a fixed policy to its exact infinite-horizon fixed point,
then improves the policy until stable. `q_learning` is a model-free temporal
difference update from one transition sample, not a planning algorithm over a
known MDP. `minimum_mean_cycle_howard` also uses a policy-iteration framework,
but evaluates graph cycles by their mean weight and bias to solve a different
minimum-mean-cycle problem; it does not evaluate discounted state values or
greedily choose MDP actions.

Chapter 341 gives the policy evaluation equation and the greedy improvement
step. The bounded profile supplies exact rational arithmetic, a deterministic
initial policy, tie rule, finite input domain, and output representation. The
implementation is clean-room: no source code, prose, examples, or figures are
reproduced. See [RIGHTS.md](RIGHTS.md).

[`primary_oracle.py`](primary_oracle.py) uses cycle evaluation and policy
improvement. [`independent_oracle.py`](independent_oracle.py) enumerates all
deterministic policies and solves each policy's linear system with exact
fractions. [`workload.json`](workload.json) provides bounded fixtures;
[`verify_workload.py`](verify_workload.py) statically checks package metadata
and source inventory without launching ports. Ten language paths are listed
in [`INVENTORY.md`](INVENTORY.md).
