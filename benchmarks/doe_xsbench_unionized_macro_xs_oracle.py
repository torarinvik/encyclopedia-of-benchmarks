"""Oracle for one bounded XSBench unionized-grid macroscopic lookup."""
from __future__ import annotations

from collections.abc import Sequence

INVALID_RESULT = -1e300
FIXED_SCALE = 1_000_000
MAX_NUCLIDES = 4
MIN_GRIDPOINTS = 2
MAX_GRIDPOINTS = 5
HEADER_LENGTH = 4
MAX_COMPOSITION = MAX_NUCLIDES
MAX_UNION_POINTS = MAX_NUCLIDES * MAX_GRIDPOINTS
MAX_INPUT_LENGTH = (
    HEADER_LENGTH + 2 * MAX_COMPOSITION
    + MAX_UNION_POINTS * (7 + MAX_NUCLIDES)
)
MAX_PARSEABLE_INPUT_LENGTH = MAX_INPUT_LENGTH + 1
MAX_FIXED_COMPONENT = FIXED_SCALE
CHANNEL_COUNT = 5
GRID_RECORD_LENGTH = 1 + CHANNEL_COUNT


def _decode(raw: int) -> float:
    return float(raw) / float(FIXED_SCALE)


def _binary_search(grid: Sequence[int], quarry: int) -> int:
    """Match XSBench's binary_search return-index and endpoint rules."""
    size = len(grid)
    if grid[0] > quarry:
        return 0
    if grid[size - 1] < quarry:
        return size - 2
    minimum = 0
    maximum = size - 1
    while maximum >= minimum:
        middle = minimum + (maximum - minimum) // 2
        if grid[middle] < quarry:
            minimum = middle + 1
        elif grid[middle] > quarry:
            maximum = middle - 1
        else:
            return middle
    return maximum


def _grid_search(grid: Sequence[int], quarry: int) -> int:
    """Match XSBench's lower-index search on the unionized energy grid."""
    lower = 0
    upper = len(grid) - 1
    length = upper - lower
    while length > 1:
        examination = lower + length // 2
        if grid[examination] > quarry:
            upper = examination
        else:
            lower = examination
        length = upper - lower
    return lower


def expected_result(
    values: Sequence[int] | None,
    *,
    input_is_null: bool = False,
    input_length: int | None = None,
) -> float:
    if (
        type(input_is_null) is not bool
        or input_is_null
        or values is None
        or not isinstance(values, (list, tuple))
    ):
        return INVALID_RESULT
    if not HEADER_LENGTH <= len(values) <= MAX_INPUT_LENGTH:
        return INVALID_RESULT
    if input_length is not None and (
        type(input_length) is not int or input_length != len(values)
    ):
        return INVALID_RESULT
    if any(
        type(value) is not int or not -(1 << 63) <= value < (1 << 63)
        for value in values
    ):
        return INVALID_RESULT

    nuclides, gridpoints, material_nuclides, query_raw = values[:4]
    if (
        not 1 <= nuclides <= MAX_NUCLIDES
        or not MIN_GRIDPOINTS <= gridpoints <= MAX_GRIDPOINTS
        or not 1 <= material_nuclides <= nuclides
        or not 0 <= query_raw <= MAX_FIXED_COMPONENT
    ):
        return INVALID_RESULT

    union_points = nuclides * gridpoints
    expected_length = (
        HEADER_LENGTH + 2 * material_nuclides
        + union_points * (7 + nuclides)
    )
    if len(values) != expected_length:
        return INVALID_RESULT

    position = HEADER_LENGTH
    composition: list[tuple[int, int]] = []
    used_nuclides: set[int] = set()
    for _ in range(material_nuclides):
        nuclide_id, concentration_raw = values[position:position + 2]
        position += 2
        if (
            not 0 <= nuclide_id < nuclides
            or nuclide_id in used_nuclides
            or not 0 <= concentration_raw <= MAX_FIXED_COMPONENT
        ):
            return INVALID_RESULT
        used_nuclides.add(nuclide_id)
        composition.append((nuclide_id, concentration_raw))

    union_raw = values[position:position + union_points]
    position += union_points
    if any(not 0 <= raw <= MAX_FIXED_COMPONENT for raw in union_raw):
        return INVALID_RESULT
    if any(left >= right for left, right in zip(union_raw, union_raw[1:])):
        return INVALID_RESULT

    pointer_start = position
    pointer_count = union_points * nuclides
    pointer_raw = values[pointer_start:pointer_start + pointer_count]
    position += pointer_count
    grid_start = position
    records: list[list[tuple[int, ...]]] = []
    all_grid_energies: list[int] = []
    for nuclide in range(nuclides):
        grid: list[tuple[int, ...]] = []
        previous_energy: int | None = None
        for point in range(gridpoints):
            start = grid_start + (nuclide * gridpoints + point) * GRID_RECORD_LENGTH
            record = tuple(values[start:start + GRID_RECORD_LENGTH])
            if len(record) != GRID_RECORD_LENGTH or any(
                not 0 <= field <= MAX_FIXED_COMPONENT for field in record
            ):
                return INVALID_RESULT
            energy = record[0]
            if previous_energy is not None and energy <= previous_energy:
                return INVALID_RESULT
            previous_energy = energy
            all_grid_energies.append(energy)
            grid.append(record)
        records.append(grid)

    if sorted(all_grid_energies) != list(union_raw):
        return INVALID_RESULT

    for union_index, quarry in enumerate(union_raw):
        for nuclide in range(nuclides):
            at = pointer_start + union_index * nuclides + nuclide
            pointer = pointer_raw[union_index * nuclides + nuclide]
            if pointer != _binary_search(
                [record[0] for record in records[nuclide]], quarry
            ):
                return INVALID_RESULT
            if not 0 <= pointer < gridpoints:
                return INVALID_RESULT

    query_index = _grid_search(union_raw, query_raw)
    macro = [0.0] * CHANNEL_COUNT
    query = _decode(query_raw)
    for nuclide_id, concentration_raw in composition:
        pointer = pointer_raw[query_index * nuclides + nuclide_id]
        low_index = pointer - 1 if pointer == gridpoints - 1 else pointer
        low = records[nuclide_id][low_index]
        high = records[nuclide_id][low_index + 1]
        factor = (_decode(high[0]) - query) / (_decode(high[0]) - _decode(low[0]))
        concentration = _decode(concentration_raw)
        for channel in range(CHANNEL_COUNT):
            high_xs = _decode(high[channel + 1])
            low_xs = _decode(low[channel + 1])
            micro_xs = high_xs - factor * (high_xs - low_xs)
            macro[channel] += micro_xs * concentration

    return (
        macro[0] + 2.0 * macro[1] + 3.0 * macro[2]
        + 5.0 * macro[3] + 7.0 * macro[4]
    )
