# Binary step

Return a binary activation value for one real input.

## Contract

- The `float64_unary` ABI accepts one finite binary64 input `x` in `[-1,000,000, 1,000,000]` and returns binary64.
- The result is `1` when `x >= 0`, including zero, and `0` when `x < 0`.
- Non-finite or out-of-range inputs return `-1e300`. Valid outputs are exact; the workload declares `1e-12` relative and absolute tolerances.

## Source semantics

The pinned [Python `binary_step.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/neural_network/activation_functions/binary_step.py) applies `np.where(vector >= 0, 1, 0)` elementwise. The unary ABI presents one vector element per call. The MATLAB candidate [`threshold_without_inbuilt.m`](https://github.com/TheAlgorithms/MATLAB-Octave/blob/e150b77ad256de46c1ce3815c3d7945ac4fc28dc/algorithms/machine_learning/Activation%20Functions/Threshold%28without%20inbuilt%29.m) is a plotting script that sets entries with `x >= 0` to one; it shows the same threshold rule but does not expose a callable API.

## Workload

[`workload.json`](workload.json) covers negative, zero, positive, supported endpoint, and invalid out-of-range inputs.
