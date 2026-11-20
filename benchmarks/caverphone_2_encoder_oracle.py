"""Primary ordered-rule oracle for a bounded Caverphone 2.0 byte profile."""

from __future__ import annotations

from collections.abc import Sequence
import re

MAX_TEXT_LENGTH = 64
MAX_INPUT_LENGTH = MAX_TEXT_LENGTH + 1
MAX_PARSEABLE_INPUT_LENGTH = MAX_INPUT_LENGTH + 2
MAX_OUTPUT_BYTES = 10
I64_MIN = -(1 << 63)
I64_MAX = (1 << 63) - 1
INVALID_RESULT = -1
OUTPUT_ERROR = -2


def _encode(text: str) -> bytes:
    """Apply the ordered Caverphone 2.0 rules to already validated ASCII."""
    if not text:
        return b"1" * MAX_OUTPUT_BYTES
    value = text.lower()
    value = re.sub(r"e$", "", value)
    for pattern, replacement in (
        (r"^cough", "cou2f"),
        (r"^rough", "rou2f"),
        (r"^tough", "tou2f"),
        (r"^enough", "enou2f"),
        (r"^trough", "trou2f"),
        (r"^gn", "2n"),
        (r"mb$", "m2"),
    ):
        value = re.sub(pattern, replacement, value)
    for old, new in (
        ("cq", "2q"), ("ci", "si"), ("ce", "se"), ("cy", "sy"),
        ("tch", "2ch"), ("c", "k"), ("q", "k"), ("x", "k"),
        ("v", "f"), ("dg", "2g"), ("tio", "sio"), ("tia", "sia"),
        ("d", "t"), ("ph", "fh"), ("b", "p"), ("sh", "s2"),
        ("z", "s"),
    ):
        value = value.replace(old, new)
    value = re.sub(r"^[aeiou]", "A", value)
    value = re.sub(r"[aeiou]", "3", value)
    value = value.replace("j", "y")
    value = re.sub(r"^y3", "Y3", value)
    value = re.sub(r"^y", "A", value)
    value = value.replace("y", "3")
    for old, new in (("3gh3", "3kh3"), ("gh", "22"), ("g", "k")):
        value = value.replace(old, new)
    for letter, replacement in (
        ("s", "S"), ("t", "T"), ("p", "P"), ("k", "K"),
        ("f", "F"), ("m", "M"), ("n", "N"),
    ):
        value = re.sub(letter + r"+", replacement, value)
    value = value.replace("w3", "W3").replace("wh3", "Wh3")
    value = re.sub(r"w$", "3", value).replace("w", "2")
    value = re.sub(r"^h", "A", value).replace("h", "2")
    value = value.replace("r3", "R3")
    value = re.sub(r"r$", "3", value).replace("r", "2")
    value = value.replace("l3", "L3")
    value = re.sub(r"l$", "3", value).replace("l", "2")
    value = value.replace("2", "")
    value = re.sub(r"3$", "A", value).replace("3", "")
    return (value + "1" * MAX_OUTPUT_BYTES)[:MAX_OUTPUT_BYTES].encode("ascii")


def expected_output(
    values: Sequence[int], output_capacity: int | None = None,
    output_is_null: bool = False, input_is_null: bool = False,
    input_length: int | None = None,
) -> tuple[int, bytes]:
    """Return status and the ten-byte code for a length-prefixed ASCII name."""
    if input_length is None:
        declared = len(values) if isinstance(values, (list, tuple)) else -1
    elif type(input_length) is int and input_length >= 0:
        declared = input_length
    else:
        return INVALID_RESULT, b""
    if (not isinstance(values, (list, tuple))
            or len(values) > MAX_PARSEABLE_INPUT_LENGTH
            or any(type(x) is not int or not I64_MIN <= x <= I64_MAX for x in values)
            or type(input_is_null) is not bool
            or (input_is_null and values)
            or (not input_is_null and declared != len(values))
            or declared > MAX_PARSEABLE_INPUT_LENGTH):
        return INVALID_RESULT, b""
    if input_is_null or not 1 <= declared <= MAX_INPUT_LENGTH:
        return INVALID_RESULT, b""
    text_length = values[0]
    if (not 0 <= text_length <= MAX_TEXT_LENGTH
            or declared != text_length + 1):
        return INVALID_RESULT, b""
    text_values = values[1:]
    if any(not (65 <= x <= 90 or 97 <= x <= 122) for x in text_values):
        return INVALID_RESULT, b""
    code = _encode("".join(chr(x) for x in text_values))
    if (type(output_is_null) is not bool
            or (output_capacity is not None
                and (type(output_capacity) is not int or output_capacity < 0))):
        return INVALID_RESULT, b""
    if output_is_null or (output_capacity is not None and output_capacity < MAX_OUTPUT_BYTES):
        return OUTPUT_ERROR, b""
    return MAX_OUTPUT_BYTES, code
