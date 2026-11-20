"""Position-automaton oracle for bounded Glushkov regex search."""
from __future__ import annotations

from dataclasses import dataclass

MAX_TEXT = 24
MAX_PATTERN = 32
MAX_POSITIONS = 8


@dataclass
class Node:
    kind: str
    left: int = -1
    right: int = -1
    position: int = 0


def _parse(pattern: bytes):
    nodes: list[Node] = []
    symbols = [0]
    cursor = 0

    def add(node: Node) -> int:
        nodes.append(node)
        return len(nodes) - 1

    def expression() -> int:
        nonlocal cursor
        result = concatenation()
        while cursor < len(pattern) and pattern[cursor] == ord("|"):
            cursor += 1
            result = add(Node("alt", result, concatenation()))
        return result

    def concatenation() -> int:
        nonlocal cursor
        if cursor >= len(pattern) or pattern[cursor] in (ord("|"), ord(")")):
            raise ValueError
        result = repetition()
        while cursor < len(pattern) and pattern[cursor] not in (ord("|"), ord(")")):
            result = add(Node("concat", result, repetition()))
        return result

    def repetition() -> int:
        nonlocal cursor
        result = atom()
        if cursor < len(pattern) and pattern[cursor] == ord("*"):
            cursor += 1
            result = add(Node("star", result))
        return result

    def atom() -> int:
        nonlocal cursor
        if cursor >= len(pattern):
            raise ValueError
        token = pattern[cursor]
        cursor += 1
        if token == ord("("):
            result = expression()
            if cursor >= len(pattern) or pattern[cursor] != ord(")"):
                raise ValueError
            cursor += 1
            return result
        if token not in (ord("a"), ord("b"), ord("c"), ord(".")):
            raise ValueError
        position = len(symbols)
        symbols.append(token)
        if position > MAX_POSITIONS:
            raise ValueError
        return add(Node("pos", position=position))

    root = expression()
    if cursor != len(pattern) or not nodes or len(nodes) > 64:
        raise ValueError

    nullable = [False] * len(nodes)
    first = [0] * len(nodes)
    last = [0] * len(nodes)
    follow = [0] * (MAX_POSITIONS + 1)
    for index, node in enumerate(nodes):
        if node.kind == "pos":
            bit = 1 << node.position
            first[index] = last[index] = bit
        elif node.kind == "star":
            nullable[index] = True
            first[index] = first[node.left]
            last[index] = last[node.left]
            positions = last[node.left]
            while positions:
                bit = positions & -positions
                pos = bit.bit_length() - 1
                follow[pos] |= first[node.left]
                positions ^= bit
        else:
            a, b = node.left, node.right
            if node.kind == "alt":
                nullable[index] = nullable[a] or nullable[b]
                first[index] = first[a] | first[b]
                last[index] = last[a] | last[b]
            else:
                nullable[index] = nullable[a] and nullable[b]
                first[index] = first[a] | (first[b] if nullable[a] else 0)
                last[index] = last[b] | (last[a] if nullable[b] else 0)
                positions = last[a]
                while positions:
                    bit = positions & -positions
                    pos = bit.bit_length() - 1
                    follow[pos] |= first[b]
                    positions ^= bit
    follow[0] = first[root] | 1

    state_count = len(symbols)
    transitions = [0] * (1 << state_count)
    for subset in range(1, len(transitions)):
        bit = subset & -subset
        state = bit.bit_length() - 1
        transitions[subset] = transitions[subset ^ bit] | follow[state]
    byte_masks = [1] * 128
    for pos, symbol in enumerate(symbols[1:], 1):
        for byte in range(1, 128):
            if symbol == ord(".") or byte == symbol:
                byte_masks[byte] |= 1 << pos
    return transitions, byte_masks, last[root]


def _valid(values, input_is_null: bool, input_length: int | None):
    if input_is_null or len(values) < 2 or len(values) > 58:
        return None
    if input_length is not None and input_length != len(values):
        return None
    text_length, pattern_length = values[0], values[1]
    if not 0 <= text_length <= MAX_TEXT or not 1 <= pattern_length <= MAX_PATTERN:
        return None
    if len(values) != 2 + text_length + pattern_length:
        return None
    raw = values[2:]
    if any(not 1 <= value <= 127 for value in raw):
        return None
    text = bytes(raw[:text_length])
    pattern = bytes(raw[text_length:])
    try:
        compiled = _parse(pattern)
    except (ValueError, RecursionError):
        return None
    return text, compiled


def expected_output(values, *, capacity: int | None = None,
                    output_is_null: bool = False, input_is_null: bool = False,
                    input_length: int | None = None) -> tuple[int, bytes]:
    valid = _valid(values, input_is_null, input_length)
    if valid is None:
        return -1, b""
    text, (transitions, byte_masks, accepting) = valid
    if text and (output_is_null or (capacity is not None and capacity < len(text))):
        return -2, b""
    state = 1
    output = bytearray()
    for byte in text:
        state = transitions[state] & byte_masks[byte]
        output.append(1 if state & accepting else 0)
    return len(output), bytes(output)
