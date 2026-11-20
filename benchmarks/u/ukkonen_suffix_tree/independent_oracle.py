"""Independent suffix-trie compression reference for Ukkonen's tree output."""

from __future__ import annotations

from collections.abc import Sequence

MAX_TEXT_LENGTH = 64
MAX_INPUT_LENGTH = 66
TERMINATOR = 4
MAX_NODES = 130
MAX_DISTINCT_SUBSTRINGS = 2_080
MAX_TOKENS = 8_903
MAX_HASH = 2_576_350_140
MAX_RESULT = (MAX_NODES << 44) | (MAX_DISTINCT_SUBSTRINGS << 32) | MAX_HASH


def expected_result(values: Sequence[int] | None, input_is_null: bool = False,
                    input_length: int | None = None) -> int:
    if (type(input_is_null) is not bool or input_is_null
            or not isinstance(values, (list, tuple))
            or not 1 <= len(values) <= MAX_INPUT_LENGTH
            or any(type(value) is not int or not -(1 << 63) <= value < (1 << 63)
                   for value in values)
            or input_length is not None
            and (type(input_length) is not int or input_length != len(values))):
        return -1
    length = values[0]
    if not 0 <= length <= MAX_TEXT_LENGTH or len(values) != length + 1:
        return -1
    text = list(values[1:])
    if any(not 0 <= symbol <= 3 for symbol in text):
        return -1
    text.append(TERMINATOR)

    # Build an ordinary suffix trie, marking each suffix endpoint. The unique
    # terminal guarantees that no endpoint has descendants.
    trie: dict = {"children": {}, "suffix_start": -1}
    for suffix_start in range(len(text)):
        node = trie
        for symbol in text[suffix_start:]:
            node = node["children"].setdefault(symbol, {"children": {}, "suffix_start": -1})
        node["suffix_start"] = suffix_start

    def compress(node: dict) -> list[tuple[list[int], int, list]]:
        edges: list[tuple[list[int], int, list]] = []
        for symbol in sorted(node["children"]):
            label = [symbol]
            child = node["children"][symbol]
            while child["suffix_start"] < 0 and len(child["children"]) == 1:
                next_symbol = next(iter(child["children"]))
                label.append(next_symbol)
                child = child["children"][next_symbol]
            edges.append((label, child["suffix_start"], compress(child)))
        return edges

    tree = compress(trie)

    def count_nodes(edges: list[tuple[list[int], int, list]]) -> int:
        return sum(1 + count_nodes(children) for _label, _suffix, children in edges)

    node_count = 1 + count_nodes(tree)
    tokens = [0]
    distinct_substrings = 0

    def emit(edges: list[tuple[list[int], int, list]]) -> None:
        nonlocal distinct_substrings
        for label, suffix_start, children in edges:
            tokens.extend((1, len(label)))
            tokens.extend(symbol + 1 for symbol in label)
            distinct_substrings += sum(symbol != TERMINATOR for symbol in label)
            if suffix_start >= 0:
                tokens.extend((2, suffix_start + 1))
            else:
                tokens.append(3)
                emit(children)
                tokens.append(4)

    emit(tree)
    tokens.append(4)
    if (node_count > MAX_NODES or distinct_substrings > MAX_DISTINCT_SUBSTRINGS
            or len(tokens) > MAX_TOKENS):
        return -1
    weighted_hash = sum(rank * token for rank, token in enumerate(tokens, start=1))
    if weighted_hash > MAX_HASH:
        return -1
    result = (node_count << 44) | (distinct_substrings << 32) | weighted_hash
    return result if result <= MAX_RESULT else -1
