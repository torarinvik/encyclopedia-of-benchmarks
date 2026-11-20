"""Primary bounded LZ78RL reference: run transform plus trie-based LZ78."""

import struct

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
    if not isinstance(values, (list, tuple)):
        return None
    if input_length is not None and input_length != len(values):
        return None
    if not 1 <= len(values) <= MAX_PARSEABLE_INPUT_LENGTH:
        return None
    n = values[0]
    if type(n) is not int or not 0 <= n <= MAX_TEXT_LENGTH or len(values) != n + 1:
        return None
    if any(type(value) is not int or not 1 <= value <= 3 for value in values[1:]):
        return None
    return values[1:]


def transform_runs(symbols):
    """Replace each maximal alpha^m run with MSB-first binary(m), 1=alpha, 0=0."""
    transformed = []
    position = 0
    while position < len(symbols):
        symbol = symbols[position]
        end = position + 1
        while end < len(symbols) and symbols[end] == symbol:
            end += 1
        run_length = end - position
        for bit in range(run_length.bit_length() - 1, -1, -1):
            transformed.append(symbol if (run_length >> bit) & 1 else 0)
        position = end
    return transformed


def lz78_tokens_trie(transformed):
    """Return (parent phrase ID, next symbol, terminal tag) triples."""
    children = [{}]
    tokens = []
    position = 0
    while position < len(transformed):
        node = 0
        end = position
        while end < len(transformed):
            child = children[node].get(transformed[end], 0)
            if child == 0:
                break
            node = child
            end += 1

        if end == len(transformed):
            if node != 0:
                # Zero is a legal transformed symbol; the tag marks termination.
                tokens.append((node, 0, 1))
            break

        symbol = transformed[end]
        tokens.append((node, symbol, 0))
        phrase_id = len(children)
        children[node][symbol] = phrase_id
        children.append({})
        position = end + 1
    return tokens


def encode_tokens(tokens):
    words = [len(tokens)]
    for parent_id, next_symbol, terminal_tag in tokens:
        words.extend((parent_id, next_symbol, terminal_tag))
    return b"".join(struct.pack("<q", word) for word in words)


def tokens_for_symbols(symbols):
    return lz78_tokens_trie(transform_runs(symbols))


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
