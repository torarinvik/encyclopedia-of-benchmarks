"""Semantic oracle for the bounded radix-tree operation trace."""

from __future__ import annotations

from collections.abc import Sequence

MAX_OPERATIONS = 256
MAX_WORD_LENGTH = 32
MAX_PARSEABLE_INPUT_LENGTH = 8_706
MAX_VALID_INPUT_LENGTH = 1 + MAX_OPERATIONS * (2 + MAX_WORD_LENGTH)
I64_MIN = -(1 << 63)
I64_MAX = (1 << 63) - 1
INVALID_RESULT = -1
MIN_LETTER = ord("a")
MAX_LETTER = ord("z")


class _RadixNode:
    """A small source-semantic model, including the pinned root-collapse behavior."""

    def __init__(self, prefix: str = "", is_leaf: bool = False) -> None:
        self.nodes: dict[str, _RadixNode] = {}
        self.is_leaf = is_leaf
        self.prefix = prefix

    def _match(self, word: str) -> tuple[str, str, str]:
        length = 0
        for left, right in zip(self.prefix, word):
            if left != right:
                break
            length += 1
        return self.prefix[:length], self.prefix[length:], word[length:]

    def insert(self, word: str) -> None:
        if word == "":
            self.is_leaf = True
            return

        if self.prefix == word and not self.is_leaf:
            self.is_leaf = True
        elif word[0] not in self.nodes:
            self.nodes[word[0]] = _RadixNode(prefix=word, is_leaf=True)
        else:
            incoming_node = self.nodes[word[0]]
            matching_string, remaining_prefix, remaining_word = incoming_node._match(word)
            if remaining_prefix == "":
                self.nodes[matching_string[0]].insert(remaining_word)
            else:
                incoming_node.prefix = remaining_prefix
                aux_node = self.nodes[matching_string[0]]
                self.nodes[matching_string[0]] = _RadixNode(matching_string, False)
                self.nodes[matching_string[0]].nodes[remaining_prefix[0]] = aux_node
                if remaining_word == "":
                    self.nodes[matching_string[0]].is_leaf = True
                else:
                    self.nodes[matching_string[0]].insert(remaining_word)

    def find(self, word: str) -> bool:
        incoming_node = self.nodes.get(word[0])
        if incoming_node is None:
            return False
        _, remaining_prefix, remaining_word = incoming_node._match(word)
        if remaining_prefix != "":
            return False
        if remaining_word == "":
            return incoming_node.is_leaf
        return incoming_node.find(remaining_word)

    def delete(self, word: str) -> bool:
        incoming_node = self.nodes.get(word[0])
        if incoming_node is None:
            return False
        _, remaining_prefix, remaining_word = incoming_node._match(word)
        if remaining_prefix != "":
            return False
        if remaining_word != "":
            return incoming_node.delete(remaining_word)
        if not incoming_node.is_leaf:
            return False

        if len(incoming_node.nodes) == 0:
            del self.nodes[word[0]]
            if len(self.nodes) == 1 and not self.is_leaf:
                merging_node = next(iter(self.nodes.values()))
                self.is_leaf = merging_node.is_leaf
                self.prefix += merging_node.prefix
                self.nodes = merging_node.nodes
        elif len(incoming_node.nodes) > 1:
            incoming_node.is_leaf = False
        else:
            merging_node = next(iter(incoming_node.nodes.values()))
            incoming_node.is_leaf = merging_node.is_leaf
            incoming_node.prefix += merging_node.prefix
            incoming_node.nodes = merging_node.nodes
        return True


def expected_result(values: Sequence[int] | None) -> int:
    """Return the weighted find/delete checksum, or -1 for invalid input."""
    if (
        not isinstance(values, (list, tuple))
        or len(values) > MAX_PARSEABLE_INPUT_LENGTH
        or any(
            type(value) is not int or not I64_MIN <= value <= I64_MAX
            for value in values
        )
        or len(values) < 1
    ):
        return INVALID_RESULT

    operation_count = values[0]
    if not 0 <= operation_count <= MAX_OPERATIONS:
        return INVALID_RESULT

    root = _RadixNode()
    cursor = 1
    checksum = 0
    for operation_index in range(operation_count):
        if cursor + 2 > len(values):
            return INVALID_RESULT
        opcode, word_length = values[cursor : cursor + 2]
        cursor += 2
        if opcode not in (0, 1, 2) or not 1 <= word_length <= MAX_WORD_LENGTH:
            return INVALID_RESULT
        if cursor + word_length > len(values):
            return INVALID_RESULT
        word_bytes = values[cursor : cursor + word_length]
        cursor += word_length
        if any(not MIN_LETTER <= byte <= MAX_LETTER for byte in word_bytes):
            return INVALID_RESULT
        word = "".join(chr(byte) for byte in word_bytes)

        if opcode == 0:
            root.insert(word)
        elif opcode == 1:
            observed = root.find(word)
            checksum += (operation_index + 1) * (1 + int(observed))
        else:
            observed = root.delete(word)
            checksum += (operation_index + 1) * (1 + int(observed))

    if cursor != len(values):
        return INVALID_RESULT
    return checksum
