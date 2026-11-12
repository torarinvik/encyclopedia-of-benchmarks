# Bodytrack annealed particle filter

This benchmark models the multi-layer annealed particle-filter update used by
PARSEC Bodytrack. It isolates the tracking update from image loading, feature
extraction, articulated-body geometry, and camera projection so the same small
workload can run in every suite language. Each layer sharpens a rational
observation likelihood with a larger annealing exponent, resamples a new
particle population from the weighted population, and applies a supplied
Gaussian-shock tape scaled by that transition's annealing spread. The final
layer returns the likelihood-weighted pose estimate.

The profile is deterministic: all initial poses, resampling uniforms, and
normal shocks are supplied in the input. It uses integer fixed-point
arithmetic, so ports do not depend on platform math libraries or PRNGs. Pose
coordinates, target coordinates, and spreads are in thousandths of a pose
unit. Normal shocks are in thousandths of a standard deviation. The precise
input format, bounds, rounding rules, and output encoding are in
[`workload.json`](workload.json).

The profile bounds pose dimensions to 1–4, particles to 2–16, and annealing
layers to 1–4. An input uses the layout
`[D,N,L,target[D],beta[L],sigma[L-1],initial_pose[N*D],uniform[(L-1)*N],shock[(L-1)*N*D]]`.
Particles and shock coordinates are ordered particle-major within each layer.
The uniform tape is in unsigned Q24 units; the shock tape uses signed
millistandard-normal units.

The score at a layer is based on
`base = floor(Q24 * 100000 / (100000 + floor(sum((pose-target)^2)/10000)))`;
the layer weight is `base` raised to its integer annealing exponent in Q24,
with flooring after every multiplication. The exponents must strictly
increase. A weighted inverse-CDF draw selects each parent, after which the
integer-scaled shock is added and clamped to the profile's pose bounds. The
final weighted mean uses round-half-away-from-zero.

The multilayer continuation and repeated weighted resampling follow the
published Bodytrack workload description and annealed particle-filter method.
The rational likelihood and bounded tape interface are benchmark-specific
choices, not claims about PARSEC's image model.

## Source references

- [PARSEC 2.0: A New Benchmark Suite for Studies of Multiprocessor Systems](https://pages.cs.wisc.edu/~markhill/restricted/757/mbs09_parsec2.pdf), Bodytrack workload description.
- [Deutscher, Blake, and Reid, “Articulated Body Motion Capture by Annealed Particle Filtering,” CVPR 2000](https://www.robots.ox.ac.uk/~lav/Papers/deutscher_etal_cvpr2000/deutscher_etal_cvpr2000.html).

The workload and all implementations are original, bounded benchmark
materials; the cited works are used for algorithm attribution only.
