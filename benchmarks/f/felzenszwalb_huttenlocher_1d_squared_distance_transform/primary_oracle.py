"""Integer lower-envelope reference for the 1D squared distance transform."""

from __future__ import annotations

from collections.abc import Sequence

MAX_N = 128
MAX_COST = 1_000_000
MAX_VALID_INPUT_LENGTH = MAX_N + 1
MAX_PARSEABLE_INPUT_LENGTH = MAX_VALID_INPUT_LENGTH + 1
MAX_OUTPUT_BYTES = MAX_N * 16
WORKSPACE_BYTES = 4096
SENTINEL = -(1 << 60)


def _parse(values: Sequence[int] | None, input_length: int | None,
           input_is_null: bool) -> list[int] | None:
    if input_is_null or values is None or not isinstance(values, (list, tuple)):
        return None
    if input_length is not None and (
        type(input_length) is not int or input_length != len(values)
        or not 0 <= input_length <= MAX_PARSEABLE_INPUT_LENGTH
    ):
        return None
    if not 2 <= len(values) <= MAX_PARSEABLE_INPUT_LENGTH:
        return None
    if any(type(value) is not int or not -(1 << 63) <= value < (1 << 63)
           for value in values):
        return None
    n = values[0]
    if not 1 <= n <= MAX_N or len(values) != n + 1:
        return None
    costs = list(values[1:])
    if any(not 0 <= cost <= MAX_COST for cost in costs):
        return None
    return costs


def _floor_div(numerator: int, denominator: int) -> int:
    """Mathematical floor division for a strictly positive denominator."""
    quotient, remainder = divmod(numerator, denominator)
    return quotient


def _lower_envelope(costs: list[int]) -> tuple[list[int], list[int]]:
    n = len(costs)
    sites = [0] * n
    starts = [SENTINEL] * n
    last = 0
    for q in range(1, n):
        while True:
            p = sites[last]
            numerator = costs[q] + q * q - costs[p] - p * p
            denominator = 2 * (q - p)
            first = _floor_div(numerator, denominator) + 1
            if first > starts[last] or last == 0:
                break
            last -= 1
        last += 1
        sites[last] = q
        starts[last] = first

    values = [0] * n
    labels = [0] * n
    envelope_index = 0
    envelope_size = last + 1
    for x in range(n):
        while (envelope_index + 1 < envelope_size
               and starts[envelope_index + 1] <= x):
            envelope_index += 1
        site = sites[envelope_index]
        values[x] = (x - site) * (x - site) + costs[site]
        labels[x] = site
    return values, labels


def _serialize(values: list[int], labels: list[int]) -> bytes:
    words: list[int] = []
    for value, label in zip(values, labels):
        words.extend((value, label))
    return b"".join(word.to_bytes(8, "little", signed=True) for word in words)


def expected_output(values: Sequence[int] | None, capacity: int | None = None,
                    output_is_null: bool = False, input_is_null: bool = False,
                    input_length: int | None = None) -> tuple[int, bytes]:
    if type(output_is_null) is not bool or type(input_is_null) is not bool:
        return -1, b""
    if capacity is not None and (type(capacity) is not int or capacity < 0):
        return -1, b""
    costs = _parse(values, input_length, input_is_null)
    if costs is None:
        return -1, b""
    distances, labels = _lower_envelope(costs)
    output = _serialize(distances, labels)
    if output_is_null or capacity is not None and capacity < len(output):
        return -2, b""
    return len(output), output
