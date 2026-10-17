"""Oracle for bounded compression with TheAlgorithms/Python's LZW variant."""

from __future__ import annotations

from collections.abc import Sequence
import math

MIN_INPUT_BITS = 0
MAX_INPUT_BITS = 128
MAX_INPUT_LENGTH = 1 + MAX_INPUT_BITS
MAX_PARSEABLE_INPUT_LENGTH = MAX_INPUT_LENGTH + 1
MAX_CODE_WIDTH = (MAX_INPUT_BITS + 1).bit_length()
MAX_OUTPUT_BYTES = (MAX_INPUT_BITS + 1) * MAX_CODE_WIDTH
INVALID_RESULT = -1
OUTPUT_ERROR = -2
I64_MIN = -(1 << 63)
I64_MAX = (1 << 63) - 1


def _parse(values: Sequence[int] | None) -> str | None:
    if (
        not isinstance(values, (list, tuple))
        or not 1 <= len(values) <= MAX_PARSEABLE_INPUT_LENGTH
        or any(type(value) is not int or not I64_MIN <= value <= I64_MAX for value in values)
    ):
        return None
    bit_count = values[0]
    if not MIN_INPUT_BITS <= bit_count <= MAX_INPUT_BITS:
        return None
    if len(values) != 1 + bit_count:
        return None
    encoded = values[1:]
    if any(value not in (ord("0"), ord("1")) for value in encoded):
        return None
    return "".join(chr(value) for value in encoded)


def _compress(data_bits: str) -> str | None:
    lexicon = {"0": "0", "1": "1"}
    result = ""
    curr_string = ""
    index = len(lexicon)

    for bit in data_bits:
        curr_string += bit
        if curr_string not in lexicon:
            continue
        last_match_id = lexicon[curr_string]
        result += last_match_id
        lexicon.pop(curr_string)
        lexicon[curr_string + "0"] = last_match_id

        if math.log2(index).is_integer():
            for curr_key in lexicon:
                lexicon[curr_key] = "0" + lexicon[curr_key]

        lexicon[curr_string + "1"] = bin(index)[2:]
        index += 1
        curr_string = ""

    if curr_string != "":
        max_key_length = max(len(key) for key in lexicon)
        while curr_string != "" and curr_string not in lexicon:
            if len(curr_string) >= max_key_length:
                return None
            curr_string += "0"
        if curr_string != "":
            result += lexicon[curr_string]
    return result


def expected_result(values: Sequence[int] | None) -> bytes | None:
    """Return the compressed bit string as ASCII bytes."""
    data_bits = _parse(values)
    if data_bits is None:
        return None
    compressed = _compress(data_bits)
    if compressed is None:
        return None
    output = compressed.encode("ascii")
    if len(output) > MAX_OUTPUT_BYTES:
        return None
    return output


def expected_output(
    values: Sequence[int] | None,
    output_capacity: int | None = None,
    output_is_null: bool = False,
    input_is_null: bool = False,
    input_length: int | None = None,
) -> tuple[int, bytes]:
    """Return status and compressed bytes for the signed-i64 array/byte-output ABI."""
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

    output = expected_result(values)
    if output is None:
        return INVALID_RESULT, b""
    if output_is_null or (output_capacity is not None and output_capacity < len(output)):
        return OUTPUT_ERROR, b""
    return len(output), output
