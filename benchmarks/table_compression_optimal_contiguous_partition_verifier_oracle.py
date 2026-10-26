"""Independent exhaustive-partition verifier for the bounded table DP."""

from __future__ import annotations

from collections.abc import Sequence


def _runs_cost(table: Sequence[int], rows: int, cols: int, left: int, right: int) -> int:
    run_count = 0
    previous = None
    for row in range(rows):
        for column in range(left, right):
            value = table[row * cols + column]
            if previous is None or previous != value:
                run_count += 1
            previous = value
    return run_count * 2


def _encode(values: tuple[int, int, int]) -> bytes:
    output = bytearray()
    for value in values:
        output.extend(value.to_bytes(8, "little", signed=True))
    return bytes(output)


def expected_output(values: Sequence[int] | None, output_capacity: int | None = None,
                    output_is_null: bool = False, input_is_null: bool = False,
                    input_length: int | None = None) -> tuple[int, bytes]:
    if (type(output_is_null) is not bool or type(input_is_null) is not bool
            or input_is_null or values is None or not isinstance(values, (list, tuple))
            or len(values) < 3 or len(values) > 66
            or input_length is not None and
                (type(input_length) is not int or input_length != len(values))
            or any(type(value) is not int or not -(1 << 63) <= value < (1 << 63)
                   for value in values)):
        return -1, b""
    rows, cols = values[0], values[1]
    if not 1 <= rows <= 8 or not 1 <= cols <= 8 or len(values) != 2 + rows * cols:
        return -1, b""
    table = values[2:]
    if any(symbol < 0 or symbol > 15 for symbol in table):
        return -1, b""

    best_key: tuple[int, tuple[int, ...]] | None = None
    best_result: tuple[int, int, int] | None = None
    for cut_mask in range(1 << (cols - 1)):
        cuts = [position for position in range(1, cols)
                if cut_mask & (1 << (position - 1))]
        endpoints = [0, *cuts, cols]
        total = sum(_runs_cost(table, rows, cols, endpoints[i], endpoints[i + 1])
                    for i in range(len(endpoints) - 1))
        # The DP retains the earliest last start on ties, then the same rule recursively.
        tie_key = tuple(reversed([0, *cuts]))
        key = (total, tie_key)
        if best_key is None or key < best_key:
            best_key = key
            best_result = (total, len(cuts) + 1, cut_mask)
    assert best_result is not None
    payload = _encode(best_result)
    if output_capacity is not None and (type(output_capacity) is not int or output_capacity < 0):
        return -1, b""
    if output_is_null or (output_capacity is not None and output_capacity < 24):
        return -2, b""
    return 24, payload
