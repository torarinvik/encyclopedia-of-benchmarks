"""Online Ukkonen construction and canonical scalar serialization."""

from __future__ import annotations

from collections.abc import Sequence
from dataclasses import dataclass, field

MAX_TEXT_LENGTH = 64
MAX_TEXT_SYMBOL = 3
TERMINATOR = 4
MAX_INPUT_LENGTH = MAX_TEXT_LENGTH + 1
MAX_VALID_INPUT_LENGTH = MAX_INPUT_LENGTH
MAX_PARSEABLE_INPUT_LENGTH = MAX_INPUT_LENGTH + 1
MAX_NODES = 2 * (MAX_TEXT_LENGTH + 1)
MAX_DISTINCT_SUBSTRINGS = MAX_TEXT_LENGTH * (MAX_TEXT_LENGTH + 1) // 2
MAX_TOKENS = 8_903
MAX_HASH = 2_576_350_140
MAX_RESULT = (MAX_NODES << 44) | (MAX_DISTINCT_SUBSTRINGS << 32) | MAX_HASH


@dataclass(slots=True)
class _Node:
    start: int
    end: int
    open_end: bool
    suffix_link: int
    parent: int
    suffix_start: int
    children: dict[int, int] = field(default_factory=dict)


def _parse(values: Sequence[int] | None, input_is_null: bool = False,
           input_length: int | None = None) -> list[int] | None:
    if (type(input_is_null) is not bool or input_is_null
            or not isinstance(values, (list, tuple))
            or not 1 <= len(values) <= MAX_PARSEABLE_INPUT_LENGTH
            or any(type(value) is not int or not -(1 << 63) <= value < (1 << 63)
                   for value in values)
            or input_length is not None
            and (type(input_length) is not int or input_length != len(values))):
        return None
    length = values[0]
    if not 0 <= length <= MAX_TEXT_LENGTH or len(values) != length + 1:
        return None
    symbols = list(values[1:])
    if any(not 0 <= symbol <= MAX_TEXT_SYMBOL for symbol in symbols):
        return None
    return symbols


def _construct_online(text: Sequence[int]) -> list[_Node] | None:
    # Open leaf ends all refer to the current phase index. Internal edge ends
    # are fixed, and suffix links default to the root.
    nodes = [_Node(-1, -1, False, 0, -1, -1)]
    active_node = 0
    active_edge = -1
    active_length = 0
    remaining = 0

    def new_node(start: int, end: int, open_end: bool,
                 parent: int, suffix_start: int = -1) -> int:
        if len(nodes) >= MAX_NODES:
            raise OverflowError
        nodes.append(_Node(start, end, open_end, 0, parent, suffix_start))
        return len(nodes) - 1

    try:
        for phase, symbol in enumerate(text):
            remaining += 1
            last_new_internal: int | None = None
            while remaining > 0:
                if active_length == 0:
                    active_edge = phase
                edge_symbol = text[active_edge]
                next_node = nodes[active_node].children.get(edge_symbol)

                if next_node is None:
                    suffix_start = phase - remaining + 1
                    leaf = new_node(phase, phase, True, active_node, suffix_start)
                    nodes[active_node].children[edge_symbol] = leaf
                    if last_new_internal is not None:
                        nodes[last_new_internal].suffix_link = active_node
                        last_new_internal = None
                else:
                    next_end = phase if nodes[next_node].open_end else nodes[next_node].end
                    edge_length = next_end - nodes[next_node].start + 1
                    if active_length >= edge_length:
                        active_edge += edge_length
                        active_length -= edge_length
                        active_node = next_node
                        continue

                    if text[nodes[next_node].start + active_length] == symbol:
                        if last_new_internal is not None:
                            nodes[last_new_internal].suffix_link = active_node
                            last_new_internal = None
                        active_length += 1
                        break

                    split_start = nodes[next_node].start
                    split_end = split_start + active_length - 1
                    split = new_node(split_start, split_end, False, active_node)
                    nodes[active_node].children[edge_symbol] = split
                    suffix_start = phase - remaining + 1
                    leaf = new_node(phase, phase, True, split, suffix_start)
                    nodes[split].children[symbol] = leaf
                    nodes[next_node].start += active_length
                    nodes[next_node].parent = split
                    nodes[split].children[text[nodes[next_node].start]] = next_node
                    if last_new_internal is not None:
                        nodes[last_new_internal].suffix_link = split
                    last_new_internal = split

                remaining -= 1
                if active_node == 0 and active_length > 0:
                    active_length -= 1
                    active_edge = phase - remaining + 1
                elif active_node != 0:
                    active_node = nodes[active_node].suffix_link
    except (IndexError, OverflowError):
        return None
    return nodes


def _serialize(nodes: Sequence[_Node], text: Sequence[int]) -> tuple[int, int, int] | None:
    tokens = [0]
    distinct_substrings = 0
    next_serial_id = 1

    def emit_children(parent_id: int, parent_serial_id: int) -> None:
        nonlocal distinct_substrings, next_serial_id
        for symbol in sorted(nodes[parent_id].children):
            child_id = nodes[parent_id].children[symbol]
            child = nodes[child_id]
            end = len(text) - 1 if child.open_end else child.end
            label = text[child.start:end + 1]
            if not label:
                raise ValueError
            serial_id = next_serial_id
            next_serial_id += 1
            tokens.extend((1, len(label)))
            tokens.extend(value + 1 for value in label)
            distinct_substrings += sum(value != TERMINATOR for value in label)
            if child.children:
                tokens.append(3)
                emit_children(child_id, serial_id)
                tokens.append(4)
            else:
                if child.suffix_start < 0:
                    raise ValueError
                tokens.extend((2, child.suffix_start + 1))

    try:
        emit_children(0, 0)
        tokens.append(4)
    except (IndexError, ValueError):
        return None
    if (next_serial_id != len(nodes) or len(tokens) > MAX_TOKENS
            or distinct_substrings > MAX_DISTINCT_SUBSTRINGS):
        return None
    weighted_hash = sum(rank * token for rank, token in enumerate(tokens, start=1))
    if weighted_hash > MAX_HASH:
        return None
    return next_serial_id, distinct_substrings, weighted_hash


def expected_result(values: Sequence[int] | None, input_is_null: bool = False,
                    input_length: int | None = None) -> int:
    symbols = _parse(values, input_is_null, input_length)
    if symbols is None:
        return -1
    text = [*symbols, TERMINATOR]
    nodes = _construct_online(text)
    if nodes is None:
        return -1
    serialized = _serialize(nodes, text)
    if serialized is None:
        return -1
    node_count, distinct_substrings, weighted_hash = serialized
    result = (node_count << 44) | (distinct_substrings << 32) | weighted_hash
    return result if result <= MAX_RESULT else -1
