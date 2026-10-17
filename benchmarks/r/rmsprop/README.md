# RMSprop

This benchmark performs one RMSprop update for a bounded parameter vector. It
preserves the pinned Python update order and makes the mutated moving-average
state visible in the output so each case can be compared as a complete update.

## Input

The ABI is `float64_slice_io`. Input is
`[n, state_mode, learning_rate, rho, epsilon, params..., gradients..., moving_avg...]`.
`n` is an exact integer from 0 through 32. `state_mode` is exactly 0 or 1:

- Mode 0 represents `moving_avg=None`; the source initializes an `n`-element
  zero state.
- Mode 1 supplies exactly `n` initial moving-average values. The source accepts
  longer state vectors and leaves their tail unchanged, but this benchmark
  deliberately narrows supplied state to exactly `n` values. Short state is
  outside the contract because the Python source raises during its update loop.

Learning rate is in `[1e-6, 1]`, `rho` in `[0, 0.99]`, and `epsilon` in
`[1e-8, 1]`. Parameters and gradients are each in `[-100, 100]`; supplied
moving-average values are in `[0, 10,000]`. These finite bounds keep the square
root domain positive and all updates finite.

## Update and output

For each index, in ascending order, the source first mutates the moving
average, then updates its parameter:

```text
v[i] = rho * v[i] + (1 - rho) * gradients[i]**2
params[i] = params[i] - (learning_rate / sqrt(v[i] + epsilon)) * gradients[i]
```

The output is `[updated_params..., updated_moving_avg...]`, with both vectors
in their original index order. In mode 0, the output includes the state that
the source initializes internally when `moving_avg` is absent. Each call
starts from the state encoded in its own input; no state carries between
calls.

Malformed input returns `-1`. A null output pointer or capacity below `2*n`
returns `-2` after input validation and without writes. Results are compared
with absolute and relative tolerance `1e-12` to allow binary64 square-root and
division differences across language runtimes.

## Pinned source

The source is TheAlgorithms/Python
[`rmsprop.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/machine_learning/rmsprop.py),
commit `e1a2a8b016001309a73d5fec4818c35cca139795`, function `rmsprop`. It
validates equal parameter and gradient lengths, positive learning rate,
`rho` in `[0,1)`, and positive epsilon, in that order. The benchmark's packed
adapter reports malformed inputs as `-1` before checking output storage.

The workload and independent oracle are [`workload.json`](workload.json) and
[`benchmarks/rmsprop_oracle.py`](../../rmsprop_oracle.py).
