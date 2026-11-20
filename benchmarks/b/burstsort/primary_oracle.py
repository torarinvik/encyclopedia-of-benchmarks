"""Bounded burst-trie string sorting reference."""

from __future__ import annotations

from collections.abc import Sequence

MAX_STRINGS = 16
MAX_STRING_LENGTH = 8
BUCKET_THRESHOLD = 3
MAX_VALID_INPUT_LENGTH = 1 + MAX_STRINGS * (1 + MAX_STRING_LENGTH)
MAX_PARSEABLE_INPUT_LENGTH = MAX_VALID_INPUT_LENGTH + 1
MAX_TRIE_NODES = 1 + MAX_STRINGS * MAX_STRING_LENGTH
MAX_RESULT = 53_124_864


def _parse(values: Sequence[int] | None, input_is_null: bool = False,
           input_length: int | None = None) -> list[bytes] | None:
    if (type(input_is_null) is not bool or input_is_null
            or not isinstance(values, (list, tuple))
            or not 1 <= len(values) <= MAX_PARSEABLE_INPUT_LENGTH
            or any(type(value) is not int or not -(1 << 63) <= value < (1 << 63)
                   for value in values)
            or input_length is not None
            and (type(input_length) is not int or input_length != len(values))):
        return None
    count = values[0]
    if not 0 <= count <= MAX_STRINGS:
        return None
    offset = 1
    strings: list[bytes] = []
    for _ in range(count):
        if offset >= len(values):
            return None
        length = values[offset]
        offset += 1
        if not 0 <= length <= MAX_STRING_LENGTH or offset + length > len(values):
            return None
        string_values = values[offset:offset + length]
        if any(not 0 <= byte <= 3 for byte in string_values):
            return None
        strings.append(bytes(string_values))
        offset += length
    if offset != len(values):
        return None
    return strings


def _key(value: bytes) -> int:
    """Encode a string as eight base-5 digits, with zero as the end marker."""
    return sum((byte + 1) * 5 ** (MAX_STRING_LENGTH - 1 - index)
               for index, byte in enumerate(value))


def _burstsort(strings: Sequence[bytes]) -> list[bytes] | None:
    # A node's depth is the number of prefix bytes already consumed. A leaf
    # bucket holds unresolved strings; bursting makes its next byte explicit.
    nodes: list[dict[str, object]] = [
        {"depth": 0, "bucket": [], "terminal": [], "children": None}
    ]

    def new_child(depth: int) -> int:
        if len(nodes) >= MAX_TRIE_NODES:
            raise OverflowError
        nodes.append({"depth": depth, "bucket": [], "terminal": [], "children": None})
        return len(nodes) - 1

    def insert(node_id: int, value: bytes) -> None:
        while True:
            node = nodes[node_id]
            depth = node["depth"]
            if len(value) == depth:
                node["terminal"].append(value)
                return
            children = node["children"]
            if children is not None:
                byte = value[depth]
                child_id = children.get(byte)
                if child_id is None:
                    child_id = new_child(depth + 1)
                    children[byte] = child_id
                node_id = child_id
                continue

            bucket = node["bucket"]
            bucket.append(value)
            if len(bucket) <= BUCKET_THRESHOLD:
                return

            pending = bucket[:]
            node["bucket"] = []
            node["children"] = {}
            for item in pending:
                insert(node_id, item)
            return

    try:
        for value in strings:
            insert(0, value)
    except (IndexError, OverflowError):
        return None

    ordered: list[bytes] = []

    def emit(node_id: int) -> None:
        node = nodes[node_id]
        ordered.extend(node["terminal"])
        ordered.extend(sorted(node["bucket"]))
        children = node["children"]
        if children is not None:
            for byte in sorted(children):
                emit(children[byte])

    emit(0)
    return ordered


def expected_result(values: Sequence[int] | None, input_is_null: bool = False,
                    input_length: int | None = None) -> int:
    strings = _parse(values, input_is_null, input_length)
    if strings is None:
        return -1
    ordered = _burstsort(strings)
    if ordered is None:
        return -1
    result = sum(rank * _key(value) for rank, value in enumerate(ordered, start=1))
    return result if result <= MAX_RESULT else -1
