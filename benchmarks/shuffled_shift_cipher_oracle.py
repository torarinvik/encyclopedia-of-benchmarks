"""Oracle for the deterministic bounded shuffled-shift cipher workload."""

from __future__ import annotations

from collections.abc import Sequence
import string

MIN_PASSCODE_LENGTH = 1
MAX_PASSCODE_LENGTH = 20
MIN_TEXT_LENGTH = 0
MAX_TEXT_LENGTH = 256
MAX_VALID_INPUT_LENGTH = 2 + MAX_PASSCODE_LENGTH + MAX_TEXT_LENGTH
MAX_PARSEABLE_INPUT_LENGTH = MAX_VALID_INPUT_LENGTH + 1
MAX_OUTPUT_BYTES = MAX_TEXT_LENGTH
INVALID_RESULT = -1
OUTPUT_ERROR = -2
I64_MIN = -(1 << 63)
I64_MAX = (1 << 63) - 1

ALPHABET = string.ascii_letters + string.digits + string.punctuation + " \t\n"
_ALPHABET_INDEX = {character: index for index, character in enumerate(ALPHABET)}
_ALPHABET_CODEPOINTS = {ord(character) for character in ALPHABET}


def _is_ascii_alphanumeric(value: int) -> bool:
    return (
        0x30 <= value <= 0x39
        or 0x41 <= value <= 0x5A
        or 0x61 <= value <= 0x7A
    )


def _parse(values: Sequence[int] | None) -> tuple[str, str] | None:
    if (
        not isinstance(values, (list, tuple))
        or not 2 <= len(values) <= MAX_PARSEABLE_INPUT_LENGTH
        or any(
            type(value) is not int or not I64_MIN <= value <= I64_MAX
            for value in values
        )
    ):
        return None

    passcode_length, text_length = values[:2]
    if not MIN_PASSCODE_LENGTH <= passcode_length <= MAX_PASSCODE_LENGTH:
        return None
    if not MIN_TEXT_LENGTH <= text_length <= MAX_TEXT_LENGTH:
        return None
    if len(values) != 2 + passcode_length + text_length:
        return None

    passcode_values = values[2 : 2 + passcode_length]
    text_values = values[2 + passcode_length :]
    if any(not _is_ascii_alphanumeric(value) for value in passcode_values):
        return None
    if any(value not in _ALPHABET_CODEPOINTS for value in text_values):
        return None
    passcode = "".join(chr(value) for value in passcode_values)
    plaintext = "".join(chr(value) for value in text_values)
    return passcode, plaintext


def _make_key(passcode: str) -> list[str]:
    breakpoints = set(passcode)
    key: list[str] = []
    segment: list[str] = []
    for character in ALPHABET:
        segment.append(character)
        if character in breakpoints or character == ALPHABET[-1]:
            key.extend(reversed(segment))
            segment.clear()
    return key


def _encrypt(passcode: str, plaintext: str) -> bytes:
    key = _make_key(passcode)
    signed_sum = sum(
        ord(character) if index % 2 == 0 else -ord(character)
        for index, character in enumerate(passcode)
    )
    shift = signed_sum if signed_sum > 0 else len(passcode)
    ciphertext = "".join(
        key[(key.index(character) + shift) % len(key)]
        for character in plaintext
    )
    return ciphertext.encode("ascii")


def expected_output(
    values: Sequence[int] | None,
    output_capacity: int | None = None,
    output_is_null: bool = False,
    input_is_null: bool = False,
    input_length: int | None = None,
) -> tuple[int, bytes]:
    """Return result byte count and cipher bytes, or the ABI error sentinel."""
    if type(output_is_null) is not bool or type(input_is_null) is not bool:
        return INVALID_RESULT, b""
    if output_capacity is not None and (
        type(output_capacity) is not int or output_capacity < 0
    ):
        return INVALID_RESULT, b""
    if input_length is not None and (
        type(input_length) is not int or input_length < 0
    ):
        return INVALID_RESULT, b""
    if input_is_null or not isinstance(values, (list, tuple)):
        return INVALID_RESULT, b""
    if input_length is not None and input_length != len(values):
        return INVALID_RESULT, b""

    parsed = _parse(values)
    if parsed is None:
        return INVALID_RESULT, b""
    output = _encrypt(*parsed)
    if output_is_null or (
        output_capacity is not None and output_capacity < len(output)
    ):
        return OUTPUT_ERROR, b""
    return len(output), output
