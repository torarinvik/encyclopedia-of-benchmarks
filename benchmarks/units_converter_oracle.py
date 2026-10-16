"""Oracle for the bounded pinned Java UnitsConverter graph closure."""

from __future__ import annotations

import math

MAX_UNITS = 8
MAX_EDGES = MAX_UNITS - 1
MAX_VALUE_MICRO = 1_000_000_000_000
MAX_SLOPE_PPM = 5_000_000
MAX_INTERCEPT_MICRO = 1_000_000_000_000
MAX_INPUT_LENGTH = 6 + 4 * MAX_EDGES + 1  # admit one extra packed value
INVALID_RESULT = -1.0e300

# (from unit, to unit, slope, intercept), matching UnitConversions.TEMPERATURE.
TEMPERATURE_EDGES = (
    (0, 1, 1.0, -273.15),       # Kelvin -> Celsius
    (1, 2, 9.0 / 5.0, 32.0),   # Celsius -> Fahrenheit
    (3, 1, 5.0 / 4.0, 0.0),    # Réaumur -> Celsius
    (4, 1, -2.0 / 3.0, 100.0),# Delisle -> Celsius
    (5, 0, 5.0 / 9.0, 0.0),    # Rankine -> Kelvin
)


def _add_if_needed(entries: dict[tuple[int, int], tuple[int, int, float, float]],
                   conversion: tuple[int, int, float, float]) -> None:
    source, target, _, _ = conversion
    if source == target:
        return
    if (source, target) in entries:
        return
    entries[(source, target)] = conversion


def _ordered(entries: dict[tuple[int, int], tuple[int, int, float, float]],
             unit_count: int) -> list[tuple[int, int, float, float]]:
    return [entries[(source, target)]
            for source in range(unit_count)
            for target in range(unit_count)
            if (source, target) in entries]


def _add_all(known: list[tuple[int, int, float, float]],
             unit_count: int) -> list[tuple[int, int, float, float]]:
    known_by_pair = {(source, target): (source, target, slope, intercept)
                     for source, target, slope, intercept in known}
    inverted: dict[tuple[int, int], tuple[int, int, float, float]] = {}
    for source in range(unit_count):
        for target in range(unit_count):
            conversion = known_by_pair.get((source, target))
            if conversion is None:
                continue
            _, _, slope, intercept = conversion
            _add_if_needed(inverted, conversion)
            _add_if_needed(inverted, (target, source, 1.0 / slope, -intercept / slope))

    result: dict[tuple[int, int], tuple[int, int, float, float]] = {}
    for first_source in range(unit_count):
        for middle in range(unit_count):
            first = inverted.get((first_source, middle))
            if first is None:
                continue
            _, _, first_slope, first_intercept = first
            _add_if_needed(result, first)
            for target in range(unit_count):
                second = inverted.get((middle, target))
                if second is None:
                    continue
                _, _, second_slope, second_intercept = second
                _add_if_needed(
                    result,
                    (first_source, target,
                     second_slope * first_slope,
                     second_slope * first_intercept + second_intercept),
                )
    return _ordered(result, unit_count)


def _is_i64_values(values: object) -> bool:
    return (isinstance(values, (list, tuple))
            and all(type(value) is int and -(2**63) <= value <= 2**63 - 1
                    for value in values))


def expected_result(values: list[int]) -> float:
    if not _is_i64_values(values) or not 4 <= len(values) <= MAX_INPUT_LENGTH:
        return INVALID_RESULT

    profile = values[0]
    if profile == 0:
        if len(values) != 4:
            return INVALID_RESULT
        source, target, value_micro = values[1:]
        unit_count = 6
        edges = list(TEMPERATURE_EDGES)
    elif profile == 1:
        if len(values) < 6:
            return INVALID_RESULT
        unit_count, edge_count, source, target, value_micro = values[1:6]
        if (not 2 <= unit_count <= MAX_UNITS or not 0 <= edge_count <= unit_count - 1
                or len(values) != 6 + 4 * edge_count):
            return INVALID_RESULT
        parent = list(range(unit_count))

        def find(unit: int) -> int:
            while parent[unit] != unit:
                parent[unit] = parent[parent[unit]]
                unit = parent[unit]
            return unit

        edges = []
        for offset in range(6, len(values), 4):
            edge_source, edge_target, slope_ppm, intercept_micro = values[offset:offset + 4]
            if (not 0 <= edge_source < unit_count or not 0 <= edge_target < unit_count
                    or edge_source == edge_target
                    or slope_ppm == 0 or abs(slope_ppm) > MAX_SLOPE_PPM
                    or abs(intercept_micro) > MAX_INTERCEPT_MICRO):
                return INVALID_RESULT
            source_root, target_root = find(edge_source), find(edge_target)
            if source_root == target_root:
                return INVALID_RESULT
            parent[source_root] = target_root
            edges.append((edge_source, edge_target,
                          slope_ppm / 1_000_000.0, intercept_micro / 1_000_000.0))
    else:
        return INVALID_RESULT

    if (not 0 <= source < unit_count or not 0 <= target < unit_count or source == target
            or not -MAX_VALUE_MICRO <= value_micro <= MAX_VALUE_MICRO):
        return INVALID_RESULT

    known = edges
    for _ in range(MAX_UNITS + 1):
        expanded = _add_all(known, unit_count)
        if len(expanded) == len(known):
            known = expanded
            break
        known = expanded
    else:
        return INVALID_RESULT

    for edge_source, edge_target, slope, intercept in known:
        if edge_source == source and edge_target == target:
            result = slope * (value_micro / 1_000_000.0) + intercept
            return result if math.isfinite(result) else INVALID_RESULT
    return INVALID_RESULT
