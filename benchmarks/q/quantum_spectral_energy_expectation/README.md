# Quantum spectral energy expectation

This profile returns the Hamiltonian expectation for a supplied normalized complex wavefunction on a periodic one-dimensional grid. It applies the kinetic operator in Fourier space and the potential operator pointwise.

## Contract

- ABI: `i64_array_float64`. Input is `[N,V_q[N],psi_re_q[N],psi_im_q[N]]`.
- `N` is a power of two from 2 through 32. The exact input length is `1+3N`; the largest valid frame has 97 words and the largest parseable frame has 98.
- All payload values are signed Q8 fixed point with scale 256. The grid is a periodic unit interval, `dx=1/N`, and `hbar=m=1`. Potential and wavefunction components are each bounded to `[-2048,2048]`.
- Require exact discrete normalization `sum(psi_re_q[j]^2+psi_im_q[j]^2)=256^2*N`.
- Signed frequency bins use `f_j=j` through `N/2` and `f_j=j-N` afterward; `k_j=2*pi*f_j`. Compute `Tpsi=IFFT((k_j^2/2)*FFT(psi))`, with an unnormalized forward transform and an inverse normalized by `N`.
- Return `E=(1/N)*sum_j Re(conj(psi[j])*(Tpsi[j]+V[j]*psi[j]))` as binary64. Invalid input returns `-1e300`. The comparison tolerances are absolute `1e-9` and relative `1e-10`.

## Method and complexity

The primary uses an iterative radix-2 Cooley–Tukey transform, multiplies each frequency bin by the spectral kinetic multiplier, transforms back, and reduces the kinetic and potential contributions. It runs in `O(N log N)` time and uses `O(N)` auxiliary storage. The independent oracle evaluates the forward and inverse transforms with direct DFT sums in `O(N^2)` time and `O(N)` scratch.

The operation is distinct from [`split_operator_imaginary_time`](../split_operator_imaginary_time/README.md): that benchmark evolves and renormalizes a state over time, while this one returns the energy functional for one supplied state. It is also distinct from classical kinetic and potential energy formulas, which do not apply the quantum spectral operator to a complex wavefunction.

## Source and rights

Method context comes from the Energy Calculations section of the Algorithm Archive [Quantum Systems chapter](https://www.algorithm-archive.org/contents/quantum_systems/quantum_systems.html). The Archive states that its code examples use MIT terms and its chapter text uses CC BY-SA 4.0. This package uses the algorithm idea only; no source code, chapter prose, examples, figures, or tests are reused. The implementations and bounded fixtures are independently authored.

## Package files

- [`workload.json`](workload.json) defines the call contract and fixtures.
- [`primary_oracle.py`](primary_oracle.py) implements the radix-2 spectral method.
- [`independent_oracle.py`](independent_oracle.py) uses direct DFT sums.
- [`verify_workload.py`](verify_workload.py) reconciles the fixture outputs.
- [`check_inventory.py`](check_inventory.py) checks the static port inventory.
- [`RIGHTS.md`](RIGHTS.md) records the clean-room and licensing review.
- [`INVENTORY.md`](INVENTORY.md) lists all language sources.

