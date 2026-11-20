"""Three-pass Ahlbach-style addition of canonical Zeckendorf bit vectors."""

from __future__ import annotations

from collections.abc import Sequence

MAX_BITS = 64
MAX_VALID_INPUT_LENGTH = 2 + 2 * MAX_BITS
MAX_PARSEABLE_INPUT_LENGTH = MAX_VALID_INPUT_LENGTH + 1
MAX_OUTPUT_BYTES = MAX_BITS + 2
MAX_WORKSPACE_BYTES = 256
I64_MIN = -(1 << 63)
I64_MAX = (1 << 63) - 1


def _canonical(bits: list[int]) -> bool:
    if not bits or any(bit not in (0, 1) for bit in bits):
        return False
    if len(bits) == 1 and bits[0] == 0:
        return True
    if bits[0] != 1:
        return False
    return all(bits[index] + bits[index + 1] <= 1
               for index in range(len(bits) - 1))


def _parse(values: Sequence[int]) -> tuple[list[int], list[int]] | None:
    if not (4 <= len(values) <= MAX_PARSEABLE_INPUT_LENGTH):
        return None
    first_length = values[0]
    if not (1 <= first_length <= MAX_BITS):
        return None
    second_length_index = first_length + 1
    if second_length_index >= len(values):
        return None
    second_length = values[second_length_index]
    if not (1 <= second_length <= MAX_BITS):
        return None
    if len(values) != second_length_index + second_length + 1:
        return None
    first = values[1:second_length_index]
    second = values[second_length_index + 1:]
    if not _canonical(first) or not _canonical(second):
        return None
    return first, second


def _stage_one(digits: list[int]) -> None:
    """Normalize the redundant 0/1/2 sum with one left-to-right pass."""
    for index in range(len(digits) - 3):
        a, b, c, x = digits[index:index + 4]
        if (a, b, c) == (0, 2, 0):
            digits[index:index + 4] = [1, 0, 0, x + 1]
        elif (a, b, c) == (0, 3, 0):
            digits[index:index + 4] = [1, 1, 0, x + 1]
        elif (a, b, c) == (0, 2, 1):
            digits[index:index + 3] = [1, 1, 0]
        elif (a, b, c) == (0, 1, 2):
            digits[index:index + 3] = [1, 0, 1]

    # The finite left-to-right scan ends with fewer than four actual digits.
    # These boundary rewrites are the paper's cleanup for transient 2s/3s.
    if len(digits) >= 3 and digits[-3:] == [0, 3, 0]:
        digits[-3:] = [1, 1, 1]
    elif len(digits) >= 3 and digits[-3:] == [0, 2, 0]:
        digits[-3:] = [1, 0, 1]
    elif len(digits) >= 4 and digits[-4:] == [0, 1, 2, 0]:
        digits[-4:] = [1, 0, 1, 0]
    elif len(digits) >= 3 and digits[-3:] == [0, 2, 1]:
        # The four-window rule 021x->110x with omitted final x=0.
        digits[-3:] = [1, 1, 0]

    if len(digits) >= 2 and digits[-2:] == [0, 3]:
        digits[-2:] = [1, 1]
    elif len(digits) >= 2 and digits[-2:] == [0, 2]:
        digits[-2:] = [1, 0]
    elif len(digits) >= 3 and digits[-3:] == [0, 1, 2]:
        digits[-3:] = [1, 0, 1]


def add(first: list[int], second: list[int]) -> bytes:
    """Return the canonical high-weight-first ASCII bits for the sum."""
    width = max(len(first), len(second))
    digits = [0] * (width + 1)  # leading zero required by the first pass
    first_offset = width - len(first)
    second_offset = width - len(second)
    for position in range(width):
        a = first[position - first_offset] if position >= first_offset else 0
        b = second[position - second_offset] if position >= second_offset else 0
        digits[position + 1] = a + b

    _stage_one(digits)

    # The right-to-left pass can move a carry beyond the first-stage width.
    # Keep this extra high-order sentinel, e.g. 4+4: 1011 -> 01011 -> 10000.
    digits.insert(0, 0)
    for index in range(len(digits) - 3, -1, -1):
        if digits[index:index + 3] == [0, 1, 1]:
            digits[index:index + 3] = [1, 0, 0]
    for index in range(len(digits) - 2):
        if digits[index:index + 3] == [0, 1, 1]:
            digits[index:index + 3] = [1, 0, 0]

    while len(digits) > 1 and digits[0] == 0:
        del digits[0]
    return bytes(48 + bit for bit in digits)


def expected_output(
    values: Sequence[int] | None,
    output_capacity: int | None = None,
    output_is_null: bool = False,
    input_is_null: bool = False,
    input_length: int | None = None,
) -> tuple[int, bytes]:
    if (type(output_is_null) is not bool or type(input_is_null) is not bool
            or output_capacity is not None
            and (type(output_capacity) is not int or output_capacity < 0)
            or input_length is not None
            and (type(input_length) is not int or not 0 <= input_length <= MAX_PARSEABLE_INPUT_LENGTH)
            or input_is_null and values not in (None, [], ())
            or not input_is_null and values is not None and not isinstance(values, (list, tuple))
            or not input_is_null and values is not None and input_length is not None
            and input_length != len(values)):
        return -1, b""
    if input_is_null or values is None or not isinstance(values, (list, tuple)):
        return -1, b""
    if (input_length is not None and input_length != len(values)
            or any(type(value) is not int or not I64_MIN <= value <= I64_MAX for value in values)):
        return -1, b""
    parsed = _parse(values)
    if parsed is None:
        return -1, b""
    output = add(*parsed)
    if output_is_null or output_capacity is not None and output_capacity < len(output):
        return -2, b""
    return len(output), output


expected_call = expected_output
