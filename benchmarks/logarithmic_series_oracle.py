"""Normalize the pinned symbolic logarithmic-series output for the ABI."""

from __future__ import annotations

MAX_INPUT_LENGTH = 3  # permit one oversized invalid array in the workload


def expected_output(values: list[int]) -> tuple[int, bytes]:
    if (not isinstance(values, list) or len(values) != 2
            or any(type(value) is not int or not -(2**63) <= value < 2**63 for value in values)):
        return -1, b""
    x_value, n_terms = values
    if not -10 <= x_value <= 10 or not -64 <= n_terms <= 256:
        return -1, b""
    if n_terms <= 0:
        return 0, b""

    delta = x_value - 1
    base = abs(delta)
    output = bytearray()
    for term in range(1, n_terms + 1):
        negative = ((delta < 0 and term % 2 == 1)
                    or (delta >= 0 and term % 2 == 0))
        if negative:
            output.append(ord("-"))
        output.extend(f"({base}^{term})/{term}\n".encode("ascii"))
    return len(output), bytes(output)
