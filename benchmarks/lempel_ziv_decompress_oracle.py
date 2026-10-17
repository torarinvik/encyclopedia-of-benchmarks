"""Oracle for bounded decoding with TheAlgorithms/Python's LZW variant."""

from __future__ import annotations

from collections.abc import Sequence
import math

MIN_INPUT_BITS = 0
MAX_INPUT_BITS = 128
MAX_INPUT_LENGTH = 1 + MAX_INPUT_BITS
MAX_PARSEABLE_INPUT_LENGTH = MAX_INPUT_LENGTH + 1
MAX_OUTPUT_BYTES = MAX_INPUT_BITS * (MAX_INPUT_BITS + 1) // 2
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


def _decode(data_bits: str) -> str:
    """Preserve the pinned decoder's dictionary mutations and operation order."""
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
        lexicon[curr_string] = last_match_id + "0"

        if math.log2(index).is_integer():
            new_lexicon: dict[str, str] = {}
            for curr_key in list(lexicon):
                new_lexicon["0" + curr_key] = lexicon.pop(curr_key)
            lexicon = new_lexicon

        lexicon[bin(index)[2:]] = last_match_id + "1"
        index += 1
        curr_string = ""
    return result


def expected_result(values: Sequence[int] | None) -> bytes | None:
    """Return decompressed ASCII bit characters, without file framing/padding."""
    data_bits = _parse(values)
    if data_bits is None:
        return None
    output = _decode(data_bits).encode("ascii")
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
    """Return status and decoded bytes for the signed-i64 array/byte-output ABI."""
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


def compress_for_fixture(data_bits: str) -> str:
    """Generate valid packed streams with the pinned source's pure compressor.

    This is only a workload-fixture generator. `expected_result` uses the
    independently implemented decoder above and never calls this helper.
    """
    if any(bit not in "01" for bit in data_bits):
        raise ValueError("fixture source data must contain only ASCII 0 and 1")
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

    while curr_string != "" and curr_string not in lexicon:
        curr_string += "0"
    if curr_string != "":
        result += lexicon[curr_string]
    return result
