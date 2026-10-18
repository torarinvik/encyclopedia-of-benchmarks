# Q-learning update step

This benchmark measures one deterministic call to the pinned Python `update()` function. It excludes epsilon-greedy action selection, random tie-breaking, grid-world movement, and the 200-episode training demo.

## Contract

Input is `[done, alpha, gamma, reward, old_q, next_action_count, next_q_values...]`. `done` is exactly 0 or 1; `alpha` and `gamma` are finite values in `[0,1]`; `reward`, `old_q`, and each next-action Q-value are finite values in `[-100,100]`. The number of next-action values is 0 through 4, and the input contains exactly `6 + next_action_count` float64 values. The maximum valid length is 10; the maximum parseable length is 11 for an extra-value framing probe.

For each call, start from a fresh Q-table, seed the current state `(0,0)` action 0 with `old_q`, and seed the distinct next state `(0,1)` actions `0..next_action_count-1` with the supplied next-state values. The adapter then applies the source's `update()` rule in its source operation order:

```text
max_q_next = 0, if done or there are no next actions
max_q_next = max(next_q_values), otherwise
new_q = (1 - alpha) * old_q + alpha * (reward + gamma * max_q_next)
```

When next actions exist and `done` is false, a negative maximum remains negative; it is not clamped to zero. The output is the updated current-state/action Q-value as one float64 element, and a valid call returns 1. The table is reset per adapter call so workload cases do not share state.

Malformed framing, invalid flags, out-of-range or nonfinite values, or a nonfinite result returns `-1` before output-buffer checks. A null output pointer or capacity below one element returns `-2` after input validation. Error returns write no output values.

The independent oracle is [`../../q_learning_oracle.py`](../../q_learning_oracle.py). The workload covers terminal and no-action transitions, positive and negative next-state maxima, endpoint learning rates, malformed inputs, and output-capacity behavior.

## Pinned source

- Python [`q_learning.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/machine_learning/q_learning.py), specifically `update(...)`. The adapter supplies explicit `alpha` and `gamma`; the source defaults and random selection methods are not used.

## Language ports

| Language | Port |
|---|---|
| C | [`c/q/q_learning.c`](../../../c/q/q_learning.c) |
| C3 | [`c3/q/q_learning.c3`](../../../c3/q/q_learning.c3) |
| C++ | [`cpp/q/q_learning.cpp`](../../../cpp/q/q_learning.cpp) |
| Elisa | [`elisa/q/q_learning.elisa`](../../../elisa/q/q_learning.elisa) |
| Nim | [`nim/q/q_learning.nim`](../../../nim/q/q_learning.nim) |
| Odin | [`odin/q/q_learning.odin`](../../../odin/q/q_learning.odin) |
| Rust | [`rust/q/q_learning.rs`](../../../rust/q/q_learning.rs) |
| V | [`v/q/q_learning.v`](../../../v/q/q_learning.v) |
| Zig | [`zig/q/q_learning.zig`](../../../zig/q/q_learning.zig) |
