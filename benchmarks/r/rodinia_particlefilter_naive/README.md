# Rodinia naive particle filter

`rodinia_particlefilter_naive` isolates one deterministic transition of the naive CUDA particle-filter core: drift/noise motion, foreground-vs-background observation likelihood, weight normalization, weighted centroid, CDF construction, and sequential systematic resampling. The synthetic video construction, disk geometry, random-number generator, CUDA copy/kernel wrappers, timing output, and file input/output are outside the profile.

## Contract

The ABI is `i64_array_scalar`, symbol `rodinia_particlefilter_naive`. Input is exactly:

```text
[particle_count, observation_sample_count, systematic_offset_micro,
 for each particle:
   x_micro, y_micro, normal_x_micro, normal_y_micro, intensity_0, ...]
```

Particle count and sample count are each 1–4. Coordinates are in [-100,100], motion innovations in [-2,2], encoded as signed integer millionths; observation intensities are integer bytes 0–255. The supplied offset is in [0,1/particle_count) and represents the source's first systematic sample `u1`. Each particle record has four fixed-point values followed by `observation_sample_count` intensity samples.

The transition applies source motion `x += 1 + 5*normal_x`, `y -= 2 - 2*normal_y` (equivalently `y = y - 2 + 2*normal_y`). It computes the source likelihood ratio `sum(((I-100)^2 - (I-228)^2)/50) / sample_count`, multiplies uniform prior weights by `exp(likelihood)`, normalizes in particle order, computes the weighted estimate, builds the cumulative distribution in order, and selects each new particle with the source's first-CDF-entry-`>=u` sequential search and fallback to the last entry. The ports preserve the source update and selection order.

The observation intensities are supplied directly, so this profile does not construct the noisy synthetic video or map particle locations through the source disk stencil. The source helper `roundDouble` returns `newValue++`; C post-increment returns the original truncated value, so it truncates toward zero despite the helper name. That detail only affects the omitted pixel-index path. The source uses time-based seeds and Box-Muller draws; this profile takes the resulting bounded normal draws and systematic offset as explicit inputs to keep the measured transition deterministic.

The scalar result is the deterministic checksum `round_away(x_estimate*1000) + 2*round_away(y_estimate*1000) + Σ_i ((2i+3)*round_away(x_resampled_i*1000) + (2i+4)*round_away(y_resampled_i*1000))`; half values round away from zero. Invalid frames or out-of-domain values return -1.

## Provenance and rights

- Pinned source: [utcs-scea/rodinia `cuda/particlefilter/ex_particle_CUDA_naive_seq.cu`](https://github.com/utcs-scea/rodinia/blob/f30e63663cfb114939a15c7ffc4ae112055ae6a8/cuda/particlefilter/ex_particle_CUDA_naive_seq.cu) at commit `f30e63663cfb114939a15c7ffc4ae112055ae6a8`; the invocation is documented in [`cuda/particlefilter/README.txt`](https://github.com/utcs-scea/rodinia/blob/f30e63663cfb114939a15c7ffc4ae112055ae6a8/cuda/particlefilter/README.txt) and [`cuda/particlefilter/run`](https://github.com/utcs-scea/rodinia/blob/f30e63663cfb114939a15c7ffc4ae112055ae6a8/cuda/particlefilter/run).
- The pinned source names Michael Trotter and Matt Goodrum. The complete University of Virginia BSD-3-Clause notice and citation list are in [`LICENSE.txt`](LICENSE.txt). These are independent implementations of the bounded recurrence; no upstream code or comments are copied.
- The workload's two-particle fixture has equal likelihoods and a hand-derived CDF tie case; the independent [Python oracle](../../rodinia_particlefilter_naive_oracle.py) covers the bounded transition.

