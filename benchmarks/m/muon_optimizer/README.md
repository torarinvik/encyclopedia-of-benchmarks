# Muon Optimizer

This benchmark traces the pinned Python `Muon` optimizer across one or more
parameter IDs. Every trace constructs a fresh optimizer. Each update receives
an explicit parameter matrix and gradient matrix; the optimizer retains a
separate velocity matrix for each ID.

## Input

The ABI is `float64_slice_io`. Input is
`[group_count, rows, columns, call_count, ns_steps, learning_rate, momentum,
events...]`. Each event is `[param_id, params[rows*columns],
gradients[rows*columns]]`; matrix entries use row-major order.

- `group_count` is 1 through 4. `rows` and `columns` are each 1 through 4.
  The matrix has at most 16 elements and `group_count*rows*columns` is at
  most 32.
- `call_count` is 1 through 8 and is at least `group_count`. Each ID from
  zero through `group_count-1` appears in the trace. Counts and IDs are exact
  integers.
- `ns_steps` is 0 through 5. The learning rate is in `[0, 0.25]`; momentum is
  in `[0, 0.99]`.
- Parameters are finite binary64 values in `[-10, 10]`; gradients are finite
  binary64 values in `[-0.01, 0.01]`.

All events in a trace use the declared matrix shape. This makes the optimizer's
per-ID velocity shape stable and avoids NumPy broadcasting behavior outside
the matrix update being benchmarked. A maximum valid input contains 271
elements; at most 64 output elements are written.

## Update and output

For each event, the source orthogonalizes the gradient. When `rows < columns`,
it transposes the matrix, performs the iterations, then transposes back. It
does not normalize the input first. Each iteration is

```text
A = 1.5*A - 0.5*A@(A.T@A)
```

The optimizer then updates the selected ID's velocity and returns new
parameters:

```text
velocity[id] = momentum*velocity[id] + orthogonalized_gradient
updated_params = params - learning_rate*velocity[id]
```

The first update for an ID starts with a zero velocity. The next event can use
that ID's previous returned parameter matrix. Output is the last returned
parameter matrix for each ID in ascending ID order, followed by each ID's
retained velocity matrix in the same order. Matrices are flattened in
row-major order. The source does not mutate the supplied parameter or gradient
arrays.

Malformed input returns `-1` before output checks. A null output pointer or
capacity below `2*group_count*rows*columns` returns `-2` without writes.
Results use absolute and relative tolerance `1e-12` for binary64 arithmetic.

## Pinned source

The source is TheAlgorithms/Python
[`muon_optimizer.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/neural_network/optimizers/muon_optimizer.py),
commit `e1a2a8b016001309a73d5fec4818c35cca139795`, class `Muon`, methods
`newton_schulz_orthogonalize` and `update`. The example and doctest driver are
excluded; each benchmark case invokes the update trace directly. The bounded
contract narrows constructor and matrix behavior to finite float64 values and
constant shapes within a trace.

The workload and independent oracle are [`workload.json`](workload.json) and
[`benchmarks/muon_optimizer_oracle.py`](../../muon_optimizer_oracle.py).
