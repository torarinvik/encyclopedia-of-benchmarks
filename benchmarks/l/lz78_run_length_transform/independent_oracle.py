"""Independent LZ78RL reference using run grouping and phrase-set scans."""

import struct
from itertools import groupby

MAX_TEXT_LENGTH = 32
MAX_VALID_INPUT_LENGTH = 33
MAX_PARSEABLE_INPUT_LENGTH = 34
MAX_TOKEN_COUNT = MAX_TEXT_LENGTH
MAX_OUTPUT_BYTES = 8 + 24 * MAX_TOKEN_COUNT


def _valid(values, input_is_null=False, input_length=None):
    if type(input_is_null) is not bool or input_is_null:
        return None
    if input_length is not None and (type(input_length) is not int or input_length < 0):
        return None
    if not isinstance(values, (tuple, list)):
        return None
    if input_length is not None and input_length != len(values):
        return None
    if not 1 <= len(values) <= MAX_PARSEABLE_INPUT_LENGTH:
        return None
    n = values[0]
    if type(n) is not int or not 0 <= n <= MAX_TEXT_LENGTH or len(values) != n + 1:
        return None
    if any(type(value) is not int or value not in (1, 2, 3) for value in values[1:]):
        return None
    return values[1:]


def _materialize_transform(symbols):
    result = []
    for symbol, run in groupby(symbols):
        count = sum(1 for _ in run)
        bits = bin(count)[2:]
        result.extend(symbol if bit == "1" else 0 for bit in bits)
    return tuple(result)


def _phrase_set_parse(text):
    # A phrase is represented by its complete tuple of symbols. The primary
    # instead walks a trie, so this reference uses separate substring probes.
    phrase_ids = {(): 0}
    tokens = []
    position = 0
    while position < len(text):
        parent_id = 0
        end = position
        while end < len(text):
            candidate = text[position:end + 1]
            if candidate not in phrase_ids:
                break
            parent_id = phrase_ids[candidate]
            end += 1

        if end == len(text):
            if parent_id != 0:
                tokens.append((parent_id, 0, 1))
            break

        symbol = text[end]
        new_phrase = text[position:end + 1]
        tokens.append((parent_id, symbol, 0))
        phrase_ids[new_phrase] = len(phrase_ids)
        position = end + 1
    return tokens


def encode_tokens(tokens):
    words = [len(tokens)]
    for parent_id, next_symbol, terminal_tag in tokens:
        words.extend((parent_id, next_symbol, terminal_tag))
    return b"".join(struct.pack("<q", word) for word in words)


def tokens_for_symbols(symbols):
    return _phrase_set_parse(_materialize_transform(symbols))


def expected_output(values, capacity=None, output_is_null=False,
                    input_is_null=False, input_length=None):
    if type(output_is_null) is not bool or type(input_is_null) is not bool:
        return -1, b""
    symbols = _valid(values, input_is_null, input_length)
    if symbols is None:
        return -1, b""
    payload = encode_tokens(tokens_for_symbols(symbols))
    if output_is_null or (capacity is not None and
                          (type(capacity) is not int or capacity < len(payload))):
        return -2, b""
    return len(payload), payload
