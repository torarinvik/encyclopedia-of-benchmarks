# Momentum SGD

This benchmark traces calls to the pinned MomentumSGD optimizer across several
parameter IDs. The optimizer retains a separate velocity for each ID; callers
provide the current parameter vector on every update. The trace exposes each
ID's last returned parameters and retained velocity.

## Input

The ABI is `float64_slice_io`. Input is
`[group_count, n, call_count, learning_rate, momentum, events...]`. Each event
is `[param_id, params[n], gradients[n]]`, in call order.

- `group_count` is 1 through 8, `n` is 1 through 16, and `call_count` is 1
  through 8. `group_count*n` must not exceed 32, and every ID from
  `0` through `group_count-1` must occur in the trace.
- IDs and the three counts are exact integers. Every event has the same vector
  width `n`; learning rate and momentum are shared for the trace.
- Learning rate is in `[1e-6, 1]`; momentum is in `[0, 0.99]`.
- Parameters and gradients are finite binary64 values in `[-1000, 1000]`.

Each trace constructs a fresh optimizer, so the velocity dictionary starts
empty. The first event for an ID therefore uses a zero velocity. The packed
contract requires exact, equal vector shapes and finite values; it narrows the
broader NumPy broadcasting and dtype behavior of the Python method.

## Update and output

For each event, the method computes a new velocity and returns a new parameter
vector:

```text
velocity[id][i] = momentum * velocity[id][i] - learning_rate * gradient[i]
updated_params[i] = params[i] + velocity[id][i]
```

The next event for an ID may use that ID's previous returned parameters; the
velocity is always retained in the optimizer under that ID. The output is
`[last_params_for_id_0, ..., last_params_for_id_(G-1),
last_velocity_for_id_0, ..., last_velocity_for_id_(G-1)]`, with each vector in
index order. Every ID appears at least once, so all output groups are defined.

Malformed input returns `-1` before output checks. A null output pointer or
capacity below `2*group_count*n` returns `-2` without writes. Results use
absolute and relative tolerance `1e-12` for binary64 arithmetic.

## Pinned source

The source is TheAlgorithms/Python
[`momentum_sgd.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/neural_network/optimizers/momentum_sgd.py),
commit `e1a2a8b016001309a73d5fec4818c35cca139795`, class `MomentumSGD`, method
`update`. The source stores velocity arrays in a dictionary keyed by
`param_id`; each workload case starts with a fresh dictionary.

The workload and independent oracle are [`workload.json`](workload.json) and
[`benchmarks/momentum_sgd_oracle.py`](../../momentum_sgd_oracle.py).
