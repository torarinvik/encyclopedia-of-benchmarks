"""Independent oracle for the bounded Rail Fence cipher contract."""

from __future__ import annotations

from collections.abc import Sequence

MAX_TEXT_LENGTH = 256
MAX_INPUT_LENGTH = 260  # one extra byte reaches malformed-length handling
MIN_RAILS = 2
MAX_RAILS = 8


def _rail_for_position(position: int, rails: int) -> int:
    period = 2 * (rails - 1)
    phase = position % period
    return phase if phase < rails else period - phase


def expected_output(values: Sequence[int], capacity: int | None = None) -> tuple[int, bytes]:
    """Return the result code and exact transformed bytes for one packed input."""
    if (not isinstance(values, Sequence) or isinstance(values, (str, bytes, bytearray))
            or not 3 <= len(values) <= MAX_INPUT_LENGTH
            or any(type(value) is not int or not -(2**63) <= value < 2**63 for value in values)):
        return -1, b""

    mode, raw_rails, raw_length = values[:3]
    if mode not in (0, 1) or not MIN_RAILS <= raw_rails <= MAX_RAILS:
        return -1, b""
    if not 0 <= raw_length <= MAX_TEXT_LENGTH or len(values) != 3 + raw_length:
        return -1, b""

    text = values[3:]
    if any(not 0 <= value <= 127 for value in text):
        return -1, b""
    if capacity is not None and (type(capacity) is not int or capacity < len(text)):
        return -2, b""

    rails = raw_rails
    if mode == 0:
        output = bytes(
            text[position]
            for rail in range(rails)
            for position in range(raw_length)
            if _rail_for_position(position, rails) == rail
        )
        return len(output), output

    rows: list[bytes] = []
    offset = 0
    for rail in range(rails):
        row_length = sum(_rail_for_position(position, rails) == rail for position in range(raw_length))
        rows.append(bytes(text[offset : offset + row_length]))
        offset += row_length

    row_positions = [0] * rails
    output = bytearray()
    for position in range(raw_length):
        rail = _rail_for_position(position, rails)
        output.append(rows[rail][row_positions[rail]])
        row_positions[rail] += 1
    return len(output), bytes(output)
