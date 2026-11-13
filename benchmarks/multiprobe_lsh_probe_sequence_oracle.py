"""Bounded best-first query-directed multi-probe LSH perturbations."""

import heapq
from collections.abc import Sequence

MAX_INPUT_LENGTH = 7
MAX_OUTPUT_BYTES = 80


def expected_output(values: Sequence[int] | None, capacity: int | None = None,
                    output_is_null: bool = False, input_is_null: bool = False,
                    input_length: int | None = None) -> tuple[int, bytes]:
    if (type(output_is_null) is not bool or type(input_is_null) is not bool
            or capacity is not None and (type(capacity) is not int or capacity < 0)
            or input_length is not None and (type(input_length) is not int or not 0 <= input_length <= 7)
            or input_is_null or values is None or not isinstance(values, (list, tuple))
            or input_length is not None and input_length != len(values)):
        return -1, b""
    if not 4 <= len(values) <= 7 or any(type(x) is not int for x in values):
        return -1, b""
    m, width, count = values[:3]
    if not 1 <= m <= 4 or not 1 <= width <= 1000 or not 0 <= count <= 3**m - 1 or len(values) != 3 + m:
        return -1, b""
    if any(not 0 <= x <= width for x in values[3:]):
        return -1, b""
    choices = sorted((distance, coordinate, sign)
                     for coordinate, lower in enumerate(values[3:])
                     for distance, sign in ((lower, -1), (width-lower, 1)))
    def entry(mask: int) -> tuple[int, int, int]:
        return (sum(choices[i][0]**2 for i in range(2*m) if mask & (1 << i)),
                mask.bit_count(), mask)
    heap = [entry(1)]
    output = bytearray()
    while len(output) < count:
        _, _, mask = heapq.heappop(heap)
        top = mask.bit_length() - 1
        if top + 1 < 2*m:
            heapq.heappush(heap, entry((mask ^ (1 << top)) | (1 << (top+1))))
            heapq.heappush(heap, entry(mask | (1 << (top+1))))
        coordinates = [choices[i][1] for i in range(2*m) if mask & (1 << i)]
        if len(set(coordinates)) == len(coordinates):
            output.append(mask)
    if output_is_null or capacity is not None and capacity < count:
        return -2, b""
    return count, bytes(output)
