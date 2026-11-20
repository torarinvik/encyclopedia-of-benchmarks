"""Character-sequence reference for the bounded Caverphone 2.0 profile."""

from __future__ import annotations

from collections.abc import Sequence
import re

MAX_TEXT_LENGTH = 64
MAX_INPUT_LENGTH = 65
MAX_PARSEABLE_INPUT_LENGTH = 67
MAX_OUTPUT_BYTES = 10
I64_MIN = -(1 << 63)
I64_MAX = (1 << 63) - 1
INVALID_RESULT = -1
OUTPUT_ERROR = -2


def _replace_all(value: str, old: str, new: str) -> str:
    """Replace non-overlapping matches from left to right in a new buffer."""
    pieces: list[str] = []
    at = 0
    while at < len(value):
        if value.startswith(old, at):
            pieces.append(new)
            at += len(old)
        else:
            pieces.append(value[at])
            at += 1
    return "".join(pieces)


def _encode_reference(text: str) -> bytes:
    if not text:
        return b"1111111111"
    value = "".join(chr(ord(ch) + 32) if "A" <= ch <= "Z" else ch for ch in text)
    if value.endswith("e"):
        value = value[:-1]
    starts = (("cough", "cou2f"), ("rough", "rou2f"), ("tough", "tou2f"),
              ("enough", "enou2f"), ("trough", "trou2f"), ("gn", "2n"))
    for old, new in starts:
        if value.startswith(old):
            value = new + value[len(old):]
            break
    if value.endswith("mb"):
        value = value[:-2] + "m2"
    replacements = (
        ("cq", "2q"), ("ci", "si"), ("ce", "se"), ("cy", "sy"),
        ("tch", "2ch"), ("c", "k"), ("q", "k"), ("x", "k"),
        ("v", "f"), ("dg", "2g"), ("tio", "sio"), ("tia", "sia"),
        ("d", "t"), ("ph", "fh"), ("b", "p"), ("sh", "s2"), ("z", "s"),
    )
    for old, new in replacements:
        value = _replace_all(value, old, new)
    chars = list(value)
    if chars and chars[0] in "aeiou":
        chars[0] = "A"
    for i in range(1, len(chars)):
        if chars[i] in "aeiou":
            chars[i] = "3"
    value = "".join(chars)
    value = _replace_all(value, "j", "y")
    if value.startswith("y3"):
        value = "Y3" + value[2:]
    elif value.startswith("y"):
        value = "A" + value[1:]
    value = _replace_all(value, "y", "3")
    for old, new in (("3gh3", "3kh3"), ("gh", "22"), ("g", "k")):
        value = _replace_all(value, old, new)
    for letter, marker in (("s", "S"), ("t", "T"), ("p", "P"), ("k", "K"),
                           ("f", "F"), ("m", "M"), ("n", "N")):
        value = re.sub(letter + r"+", marker, value)
    value = _replace_all(value, "w3", "W3")
    value = _replace_all(value, "wh3", "Wh3")
    if value.endswith("w"):
        value = value[:-1] + "3"
    value = _replace_all(value, "w", "2")
    if value.startswith("h"):
        value = "A" + value[1:]
    value = _replace_all(value, "h", "2")
    value = _replace_all(value, "r3", "R3")
    if value.endswith("r"):
        value = value[:-1] + "3"
    value = _replace_all(value, "r", "2")
    value = _replace_all(value, "l3", "L3")
    if value.endswith("l"):
        value = value[:-1] + "3"
    value = _replace_all(value, "l", "2")
    value = _replace_all(value, "2", "")
    if value.endswith("3"):
        value = value[:-1] + "A"
    value = _replace_all(value, "3", "")
    return (value + "1111111111")[:10].encode("ascii")


def expected_output(values: Sequence[int], output_capacity: int | None = None,
                    output_is_null: bool = False, input_is_null: bool = False,
                    input_length: int | None = None) -> tuple[int, bytes]:
    if input_length is None:
        declared = len(values) if isinstance(values, (list, tuple)) else -1
    elif type(input_length) is int and input_length >= 0:
        declared = input_length
    else:
        return INVALID_RESULT, b""
    if (not isinstance(values, (tuple, list)) or len(values) > MAX_PARSEABLE_INPUT_LENGTH
            or any(type(x) is not int or not I64_MIN <= x <= I64_MAX for x in values)
            or type(input_is_null) is not bool or (input_is_null and values)
            or (not input_is_null and declared != len(values))
            or declared > MAX_PARSEABLE_INPUT_LENGTH):
        return INVALID_RESULT, b""
    if input_is_null or not 1 <= declared <= MAX_INPUT_LENGTH:
        return INVALID_RESULT, b""
    size = values[0]
    if not 0 <= size <= MAX_TEXT_LENGTH or declared != size + 1:
        return INVALID_RESULT, b""
    if any(not (65 <= x <= 90 or 97 <= x <= 122) for x in values[1:]):
        return INVALID_RESULT, b""
    code = _encode_reference("".join(chr(x) for x in values[1:]))
    if (type(output_is_null) is not bool or (output_capacity is not None
            and (type(output_capacity) is not int or output_capacity < 0))):
        return INVALID_RESULT, b""
    if output_is_null or (output_capacity is not None and output_capacity < MAX_OUTPUT_BYTES):
        return OUTPUT_ERROR, b""
    return MAX_OUTPUT_BYTES, code
