"""Oracle for bounded deterministic replay of Python random_graph edge draws."""

from __future__ import annotations

from collections.abc import Sequence

MIN_VERTICES = 0
MAX_VERTICES = 64
MIN_PROBABILITY_UNITS = -(1 << 53)
MAX_PROBABILITY_UNITS = 1 << 54
DRAW_SCALE = 1 << 53
MAX_PAIR_COUNT = MAX_VERTICES * (MAX_VERTICES - 1) // 2
MAX_VALID_INPUT_LENGTH = 3 + MAX_PAIR_COUNT
MAX_PARSEABLE_INPUT_LENGTH = MAX_VALID_INPUT_LENGTH + 1
MAX_OUTPUT_BYTES = MAX_VERTICES * MAX_VERTICES
INVALID_RESULT = -1
OUTPUT_ERROR = -2


def _decode_input(values: Sequence[int] | None):
    if (not isinstance(values, (list, tuple))
            or not 3 <= len(values) <= MAX_PARSEABLE_INPUT_LENGTH):
        return None
    if any(type(value) is not int or not -(1 << 63) <= value < (1 << 63)
           for value in values):
        return None

    vertex_count, directed, probability_units = values[:3]
    if not MIN_VERTICES <= vertex_count <= MAX_VERTICES or directed not in (0, 1):
        return None
    if not MIN_PROBABILITY_UNITS <= probability_units <= MAX_PROBABILITY_UNITS:
        return None
    draw_count = (vertex_count * (vertex_count - 1) // 2
                  if 0 < probability_units < DRAW_SCALE else 0)
    if len(values) != 3 + draw_count:
        return None
    draws = values[3:]
    if any(not 0 <= draw < DRAW_SCALE for draw in draws):
        return None
    return vertex_count, directed, probability_units, draws


def _adjacency_bytes(vertex_count: int, directed: int, probability_units: int,
                     draws: Sequence[int]) -> bytes:
    adjacency = bytearray(vertex_count * vertex_count)
    if probability_units >= DRAW_SCALE:
        for source in range(vertex_count):
            for target in range(vertex_count):
                if source != target:
                    adjacency[source * vertex_count + target] = 1
    elif probability_units > 0:
        draw_index = 0
        for source in range(vertex_count):
            for target in range(source + 1, vertex_count):
                if draws[draw_index] < probability_units:
                    adjacency[source * vertex_count + target] = 1
                    if directed == 0:
                        adjacency[target * vertex_count + source] = 1
                draw_index += 1
    return bytes(adjacency)


def expected_output(
    values: Sequence[int] | None,
    capacity: int | None = None,
    output_is_null: bool = False,
    input_is_null: bool = False,
    input_length: int | None = None,
) -> tuple[int, bytes]:
    """Return the row-major adjacency matrix or the documented ABI error."""
    if type(output_is_null) is not bool or type(input_is_null) is not bool:
        return INVALID_RESULT, b""
    if input_is_null or values is None or not isinstance(values, (list, tuple)):
        return INVALID_RESULT, b""
    if input_length is not None and (
        type(input_length) is not int or input_length != len(values)
    ):
        return INVALID_RESULT, b""

    decoded = _decode_input(values)
    if decoded is None:
        return INVALID_RESULT, b""
    vertex_count, directed, probability_units, draws = decoded
    output = _adjacency_bytes(vertex_count, directed, probability_units, draws)
    if len(output) > MAX_OUTPUT_BYTES:
        return INVALID_RESULT, b""
    if capacity is not None and (type(capacity) is not int or capacity < 0):
        return INVALID_RESULT, b""
    if output_is_null or (capacity is not None and capacity < len(output)):
        return OUTPUT_ERROR, b""
    return len(output), output
