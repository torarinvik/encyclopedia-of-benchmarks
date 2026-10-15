# Doppler frequency

Compute the frequency observed for a moving source and observer using the pinned Doppler formula.

## Contract

- The `i64_array_float64` ABI accepts `[org_freq, wave_vel, obs_vel, src_vel]` and returns a binary64 frequency.
- Inputs are integer-valued: original frequency is in `[1, 1,000]` Hz, wave speed is in `[200, 1,000]` m/s, and observer/source velocities are each in `[-100, 100]` m/s.
- The result preserves the source expression order: `(org_freq * (wave_vel + obs_vel)) / (wave_vel - src_vel)`. The bounds keep both numerator factors and denominator positive, and prevent division by zero.
- Invalid length or out-of-domain inputs return `-1e300`. Valid outputs use relative and absolute tolerances of `1e-12`.

## Source semantics

The pinned [TheAlgorithms Python source](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/physics/doppler_frequency.py) is named `doppler_frequency.py`, while its exported function is `doppler_effect(org_freq, wave_vel, obs_vel, src_vel)`. It evaluates the formula above and raises for equal wave/source speeds or a nonpositive computed frequency. The benchmark bounds exclude both error cases and use a bounded integer-valued subset of the source's floating-point domain.

## Workload

[`workload.json`](workload.json) covers source and observer motion in both directions, zero velocities, domain bounds, and invalid values and lengths.
