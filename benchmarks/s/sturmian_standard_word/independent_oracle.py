"""Independent reference: compose directive morphisms over the two letters."""

from __future__ import annotations

from collections.abc import Sequence

try:
    from . import primary_oracle
except ImportError:
    import primary_oracle  # type: ignore[no-redef]

INVALID_RESULT = primary_oracle.INVALID_RESULT
OUTPUT_ERROR = primary_oracle.OUTPUT_ERROR
MAX_STEPS = primary_oracle.MAX_STEPS
MAX_VALID_INPUT_LENGTH = primary_oracle.MAX_VALID_INPUT_LENGTH
MAX_PARSEABLE_INPUT_LENGTH = primary_oracle.MAX_PARSEABLE_INPUT_LENGTH
MAX_OUTPUT_BYTES = primary_oracle.MAX_OUTPUT_BYTES
WORKSPACE_BYTES = primary_oracle.WORKSPACE_BYTES


def _read_directives(values: Sequence[int], input_is_null: bool,
                     input_length: int) -> tuple[int, ...] | None:
    if (not isinstance(values, (tuple, list)) or type(input_is_null) is not bool
            or input_is_null or type(input_length) is not int
            or input_length != len(values) or not 1 <= input_length <= 6):
        return None
    if any(type(word) is not int or not -(1 << 63) <= word < (1 << 63)
           for word in values):
        return None
    count = values[0]
    if (count < 0 or count > MAX_STEPS or input_length != count + 1
            or input_length > MAX_VALID_INPUT_LENGTH):
        return None
    digits = tuple(values[1:])
    if count > 0 and not 0 <= digits[0] <= 2:
        return None
    if any(digit < 1 or digit > 2 for digit in digits[1:]):
        return None
    return digits


def _compose(directives: tuple[int, ...]) -> bytes:
    word = b"a"
    # sigma_d(a)=a^d b and sigma_d(b)=a. Composition is outermost-first,
    # so substitutions are applied to the seed from the last directive back.
    for repeat in reversed(directives):
        expanded = bytearray()
        for letter in word:
            if letter == ord("a"):
                expanded.extend(b"a" * repeat)
                expanded.append(ord("b"))
            else:
                expanded.append(ord("a"))
        word = bytes(expanded)
    return word


def expected_output(values: Sequence[int], capacity: int | None = MAX_OUTPUT_BYTES,
                    output_is_null: bool = False, input_is_null: bool = False,
                    input_length: int | None = None) -> tuple[int, bytes]:
    effective_length = (len(values) if input_length is None and isinstance(values, (list, tuple))
                        else input_length)
    if effective_length is None:
        return INVALID_RESULT, b""
    directives = _read_directives(values, input_is_null, effective_length)
    if directives is None:
        return INVALID_RESULT, b""
    result = _compose(directives)
    if (type(output_is_null) is not bool
            or (capacity is not None and (type(capacity) is not int or capacity < 0))):
        return INVALID_RESULT, b""
    if output_is_null or (capacity is not None and capacity < len(result)):
        return OUTPUT_ERROR, b""
    return len(result), result
