"""Independent set-based oracle for the bounded MallocBench Espresso profile."""

from collections.abc import Sequence


def mallocbench_espresso(values: Sequence[int] | None, length: int | None = None) -> int:
    if values is None:
        return -1
    if length is None:
        length = len(values)
    if length != 3 or len(values) < length:
        return -1
    variable_count, on_mask, dc_mask = values[:3]
    if not isinstance(variable_count, int) or not 1 <= variable_count <= 5:
        return -1
    if not isinstance(on_mask, int) or not isinstance(dc_mask, int) or on_mask < 0 or dc_mask < 0:
        return -1
    minterm_count = 1 << variable_count
    valid_mask = (1 << minterm_count) - 1
    if (on_mask | dc_mask) & ~valid_mask or on_mask & dc_mask:
        return -1

    on_points = {m for m in range(minterm_count) if on_mask & (1 << m)}
    allowed_points = on_points | {m for m in range(minterm_count) if dc_mask & (1 << m)}
    terms: list[tuple[int, int]] = [((1 << variable_count) - 1, m) for m in sorted(on_points)]

    def points(cube: tuple[int, int]) -> set[int]:
        fixed, pattern = cube
        return {m for m in range(minterm_count) if m & fixed == pattern}

    expanded: list[tuple[int, int]] = []
    for fixed, pattern in terms:
        for bit in range(variable_count):
            proposed_fixed = fixed & ~(1 << bit)
            proposed_pattern = pattern & proposed_fixed
            if points((proposed_fixed, proposed_pattern)) <= allowed_points:
                fixed, pattern = proposed_fixed, proposed_pattern
        expanded.append((fixed, pattern))

    active = [True] * len(expanded)
    for i, cube in enumerate(expanded):
        covered_by_cube = points(cube) & on_points
        other_coverage: set[int] = set()
        for j, other in enumerate(expanded):
            if i != j and active[j]:
                other_coverage.update(points(other) & on_points)
        if covered_by_cube <= other_coverage:
            active[i] = False

    selected = [cube for i, cube in enumerate(expanded) if active[i]]
    cube_count = len(selected)
    literal_count = sum(fixed.bit_count() for fixed, _ in selected)
    return 1024 * cube_count + literal_count
