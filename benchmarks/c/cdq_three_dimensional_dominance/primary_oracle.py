"""CDQ/Fenwick oracle for three-dimensional dominance counts."""

from __future__ import annotations

MAX_N = 64
COORDINATE_MIN = -1000
COORDINATE_MAX = 1000
MAX_VALID_INPUT_LENGTH = 193
MAX_PARSEABLE_INPUT_LENGTH = 194
WORKSPACE_BYTES = 8192


def _parse(values, input_is_null=False, input_length=None):
    if input_is_null or not isinstance(values, (list, tuple)):
        return None
    if (len(values) < 1 or len(values) > MAX_PARSEABLE_INPUT_LENGTH
            or any(type(value) is not int or not -(1 << 63) <= value < (1 << 63)
                   for value in values)):
        return None
    if input_length is not None and (
        type(input_length) is not int or input_length != len(values)
    ):
        return None
    n = values[0]
    if not 1 <= n <= MAX_N or len(values) != 1 + 3 * n:
        return None
    points = []
    for i in range(n):
        x, y, z = values[1 + 3 * i:4 + 3 * i]
        if not (COORDINATE_MIN <= x <= COORDINATE_MAX
                and COORDINATE_MIN <= y <= COORDINATE_MAX
                and COORDINATE_MIN <= z <= COORDINATE_MAX):
            return None
        points.append((x, y, z))
    return points


def _bit_add(bit: list[int], index: int, delta: int, limit: int) -> None:
    while index <= limit:
        bit[index] += delta
        index += index & -index


def _bit_sum(bit: list[int], index: int) -> int:
    total = 0
    while index > 0:
        total += bit[index]
        index -= index & -index
    return total


def expected_result(values, input_is_null=False, input_length=None):
    """Return the one-based-index weighted dominance-count checksum, or -1."""
    original = _parse(values, input_is_null=input_is_null, input_length=input_length)
    if original is None:
        return -1

    multiplicities: dict[tuple[int, int, int], int] = {}
    for point in original:
        multiplicities[point] = multiplicities.get(point, 0) + 1
    triples = sorted(multiplicities)
    z_values = sorted({point[2] for point in triples})
    z_rank = {value: index + 1 for index, value in enumerate(z_values)}
    groups = [(*point, multiplicities[point], z_rank[point[2]]) for point in triples]
    group_index = {point: index for index, point in enumerate(triples)}
    original_group = [group_index[point] for point in original]
    dominated = [0] * len(groups)
    bit = [0] * (len(z_values) + 1)
    order = list(range(len(groups)))
    scratch = [0] * len(groups)

    def cdq(left: int, right: int) -> None:
        if left >= right:
            return
        middle = (left + right) // 2
        cdq(left, middle)
        cdq(middle + 1, right)

        source_cursor = left
        for target_position in range(middle + 1, right + 1):
            target = order[target_position]
            while (source_cursor <= middle
                   and groups[order[source_cursor]][1] <= groups[target][1]):
                source = order[source_cursor]
                _bit_add(bit, groups[source][4], groups[source][3], len(z_values))
                source_cursor += 1
            dominated[target] += _bit_sum(bit, groups[target][4])
        for source_position in range(left, source_cursor):
            source = order[source_position]
            _bit_add(bit, groups[source][4], -groups[source][3], len(z_values))

        left_cursor = left
        right_cursor = middle + 1
        destination = left
        while left_cursor <= middle and right_cursor <= right:
            if groups[order[left_cursor]][1] <= groups[order[right_cursor]][1]:
                scratch[destination] = order[left_cursor]
                left_cursor += 1
            else:
                scratch[destination] = order[right_cursor]
                right_cursor += 1
            destination += 1
        while left_cursor <= middle:
            scratch[destination] = order[left_cursor]
            left_cursor += 1
            destination += 1
        while right_cursor <= right:
            scratch[destination] = order[right_cursor]
            right_cursor += 1
            destination += 1
        order[left:right + 1] = scratch[left:right + 1]

    cdq(0, len(groups) - 1)
    checksum = 0
    for index, group in enumerate(original_group):
        checksum += (index + 1) * (dominated[group] + groups[group][3] - 1)
    return checksum
