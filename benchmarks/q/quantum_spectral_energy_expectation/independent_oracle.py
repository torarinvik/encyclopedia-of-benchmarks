"""Direct-DFT Hamiltonian expectation reference, independent of the FFT."""

from __future__ import annotations

import cmath
import math
from typing import Sequence

from q.quantum_spectral_energy_expectation.primary_oracle import INVALID_RESULT, NORM_SCALE, _parse


def expected_result(values: Sequence[int] | None, *, input_is_null: bool = False,
                    input_length: int | None = None) -> float:
    parsed = _parse(values, input_is_null, input_length)
    if parsed is None:
        return INVALID_RESULT
    n, potential, fixed_real, fixed_imag = parsed
    psi = [complex(re / NORM_SCALE, im / NORM_SCALE)
           for re, im in zip(fixed_real, fixed_imag)]
    transformed: list[complex] = []
    for frequency_index in range(n):
        transformed.append(sum(
            psi[position] * cmath.exp(-2j * math.pi * frequency_index * position / n)
            for position in range(n)
        ))

    kinetic: list[complex] = []
    for position in range(n):
        value = 0j
        for frequency_index, spectral_value in enumerate(transformed):
            frequency = frequency_index if frequency_index <= n // 2 else frequency_index - n
            wave_number = 2 * math.pi * frequency
            value += (0.5 * wave_number * wave_number * spectral_value
                      * cmath.exp(2j * math.pi * frequency_index * position / n))
        kinetic.append(value / n)

    energy = 0.0
    for position, sample in enumerate(psi):
        h_psi = kinetic[position] + (potential[position] / NORM_SCALE) * sample
        energy += (sample.conjugate() * h_psi).real
    return energy / n
