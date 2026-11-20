"""Independent direct minimization reference for the 1D distance transform."""

from __future__ import annotations

from collections.abc import Sequence

MAX_N = 128
MAX_COST = 1_000_000
MAX_VALID_INPUT_LENGTH = MAX_N + 1
MAX_PARSEABLE_INPUT_LENGTH = MAX_VALID_INPUT_LENGTH + 1
MAX_OUTPUT_BYTES = MAX_N * 16
WORKSPACE_BYTES = 4096


def _frame(frame: Sequence[int] | None, length: int | None,
           input_is_null: bool) -> list[int] | None:
    if input_is_null or frame is None or not isinstance(frame, (list, tuple)):
        return None
    if length is not None and (
        type(length) is not int or length != len(frame)
        or not 0 <= length <= MAX_PARSEABLE_INPUT_LENGTH
    ):
        return None
    if not 2 <= len(frame) <= MAX_PARSEABLE_INPUT_LENGTH:
        return None
    if any(type(value) is not int or not -(1 << 63) <= value < (1 << 63)
           for value in frame):
        return None
    n = frame[0]
    if not 1 <= n <= MAX_N or len(frame) != n + 1:
        return None
    costs = list(frame[1:])
    if any(cost < 0 or cost > MAX_COST for cost in costs):
        return None
    return costs


def _direct(costs: list[int]) -> list[tuple[int, int]]:
    result: list[tuple[int, int]] = []
    for x in range(len(costs)):
        best = min((cost + (x - site) ** 2, site)
                   for site, cost in enumerate(costs))
        result.append(best)
    return result


def _encode(pairs: list[tuple[int, int]]) -> bytes:
    return b"".join(word.to_bytes(8, "little", signed=True)
                    for pair in pairs for word in pair)


def expected_output(values: Sequence[int] | None, capacity: int | None = None,
                    output_is_null: bool = False, input_is_null: bool = False,
                    input_length: int | None = None) -> tuple[int, bytes]:
    if type(output_is_null) is not bool or type(input_is_null) is not bool:
        return -1, b""
    if capacity is not None and (type(capacity) is not int or capacity < 0):
        return -1, b""
    costs = _frame(values, input_length, input_is_null)
    if costs is None:
        return -1, b""
    output = _encode(_direct(costs))
    if output_is_null or capacity is not None and capacity < len(output):
        return -2, b""
    return len(output), output
