"""Independent oracle for the bounded Olden EM3D node-update kernel."""

from __future__ import annotations

import math

MIN_NODES = 1
MAX_NODES = 8
MIN_DEGREE = 1
MAX_DEGREE = 4
MAX_INPUT_LENGTH = 2 + 2 * MAX_NODES + 4 * MAX_NODES * MAX_DEGREE
INVALID_RESULT = -1
OUTPUT_ERROR = -2


def _finite_number(value: object) -> bool:
    if type(value) not in (int, float):
        return False
    try:
        return math.isfinite(float(value))
    except (OverflowError, ValueError):
        return False


def expected_output(values: list[float] | None) -> tuple[int, list[float]]:
    """Apply E-node updates, then H-node updates using the pinned source order."""
    if type(values) is not list or len(values) < 2:
        return INVALID_RESULT, []
    if any(not _finite_number(value) for value in values):
        return INVALID_RESULT, []
    raw_n, raw_degree = values[:2]
    if (not float(raw_n).is_integer() or not float(raw_degree).is_integer()):
        return INVALID_RESULT, []
    n, degree = int(raw_n), int(raw_degree)
    if not MIN_NODES <= n <= MAX_NODES or not MIN_DEGREE <= degree <= MAX_DEGREE:
        return INVALID_RESULT, []
    edge_count = n * degree
    expected_length = 2 + 2 * n + 4 * edge_count
    if len(values) != expected_length:
        return INVALID_RESULT, []
    offset = 2
    electric = [float(value) for value in values[offset:offset + n]]
    offset += n
    magnetic = [float(value) for value in values[offset:offset + n]]
    offset += n
    electric_neighbors = values[offset:offset + edge_count]
    offset += edge_count
    electric_coefficients = values[offset:offset + edge_count]
    offset += edge_count
    magnetic_neighbors = values[offset:offset + edge_count]
    offset += edge_count
    magnetic_coefficients = values[offset:offset + edge_count]

    for neighbors in (electric_neighbors, magnetic_neighbors):
        for index, neighbor in enumerate(neighbors):
            if not float(neighbor).is_integer() or not 0 <= neighbor < n:
                return INVALID_RESULT, []
            start = (index // degree) * degree
            if neighbor in neighbors[start:index]:
                return INVALID_RESULT, []
    if any(not 0.0 <= float(value) <= 1.0 for value in electric + magnetic
           + electric_coefficients + magnetic_coefficients):
        return INVALID_RESULT, []

    def update(values_to_update: list[float], source_values: list[float],
               neighbors: list[float], coefficients: list[float]) -> None:
        for node in range(n):
            current = values_to_update[node]
            base = node * degree
            for edge in range(degree):
                # The C routine uses coeffs[i] for both entries in each pair.
                coefficient_index = base + (edge & ~1)
                current -= float(coefficients[coefficient_index]) * source_values[int(neighbors[base + edge])]
            values_to_update[node] = current

    update(electric, magnetic, electric_neighbors, electric_coefficients)
    update(magnetic, electric, magnetic_neighbors, magnetic_coefficients)
    return 2 * n, electric + magnetic
