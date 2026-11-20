"""Three-level 64-ary bitmap hierarchy for a bounded predecessor set."""

from __future__ import annotations

from collections.abc import Sequence

UNIVERSE = 1 << 18
MAX_Q = 32
MAX_VALID_LENGTH = 1 + 2 * MAX_Q
MAX_PARSEABLE_LENGTH = MAX_VALID_LENGTH + 1
I64_MIN = -(1 << 63)
I64_MAX = (1 << 63) - 1
WORD_MASK = (1 << 64) - 1


def _decode(values: Sequence[int] | None, input_length: int | None,
            input_is_null: bool) -> list[tuple[int, int]] | None:
    if (type(input_is_null) is not bool or input_is_null
            or not isinstance(values, (list, tuple))
            or not 1 <= len(values) <= MAX_PARSEABLE_LENGTH
            or any(type(value) is not int or not I64_MIN <= value <= I64_MAX
                   for value in values)):
        return None
    if input_length is not None and (
            type(input_length) is not int or input_length != len(values)):
        return None
    q = values[0]
    if type(q) is not int or not 0 <= q <= MAX_Q or len(values) != 1 + 2 * q:
        return None
    operations: list[tuple[int, int]] = []
    for cursor in range(1, len(values), 2):
        opcode, key = values[cursor:cursor + 2]
        if opcode not in (0, 1, 2, 3, 4) or not 0 <= key < UNIVERSE:
            return None
        operations.append((opcode, key))
    return operations


class _BitmapSet:
    """Leaf words store keys; two 64-way summary levels skip empty words."""

    def __init__(self) -> None:
        self.leaves = [0] * 4096
        self.groups = [0] * 64
        self.top = 0

    def insert(self, key: int) -> int:
        word_index, bit_index = key >> 6, key & 63
        bit = 1 << bit_index
        old_word = self.leaves[word_index]
        if old_word & bit:
            return 0
        if old_word == 0:
            group_index, slot = word_index >> 6, word_index & 63
            old_group = self.groups[group_index]
            self.groups[group_index] = old_group | (1 << slot)
            if old_group == 0:
                self.top |= 1 << group_index
        self.leaves[word_index] = old_word | bit
        return 1

    def erase(self, key: int) -> int:
        word_index, bit_index = key >> 6, key & 63
        bit = 1 << bit_index
        old_word = self.leaves[word_index]
        if not old_word & bit:
            return 0
        new_word = old_word & ~bit
        self.leaves[word_index] = new_word
        if new_word == 0:
            group_index, slot = word_index >> 6, word_index & 63
            new_group = self.groups[group_index] & ~(1 << slot)
            self.groups[group_index] = new_group
            if new_group == 0:
                self.top &= ~(1 << group_index)
        return 1

    def contains(self, key: int) -> int:
        return int(bool(self.leaves[key >> 6] & (1 << (key & 63))))

    def successor(self, key: int) -> int:
        word_index, bit_index = key >> 6, key & 63
        candidates = self.leaves[word_index] & (WORD_MASK ^ ((1 << bit_index) - 1))
        if candidates:
            return (word_index << 6) + (candidates & -candidates).bit_length()

        group_index, slot = word_index >> 6, word_index & 63
        later_slots = self.groups[group_index] >> (slot + 1) if slot < 63 else 0
        if later_slots:
            next_word = (group_index << 6) + slot + 1 + (later_slots & -later_slots).bit_length() - 1
        else:
            later_groups = self.top >> (group_index + 1) if group_index < 63 else 0
            if not later_groups:
                return 0
            next_group = group_index + 1 + (later_groups & -later_groups).bit_length() - 1
            next_word = (next_group << 6) + (self.groups[next_group] & -self.groups[next_group]).bit_length() - 1
        next_bits = self.leaves[next_word]
        return (next_word << 6) + (next_bits & -next_bits).bit_length()

    def predecessor(self, key: int) -> int:
        word_index, bit_index = key >> 6, key & 63
        lower_bits = self.leaves[word_index] & ((1 << bit_index) - 1)
        if lower_bits:
            return (word_index << 6) + lower_bits.bit_length()

        group_index, slot = word_index >> 6, word_index & 63
        earlier_slots = self.groups[group_index] & ((1 << slot) - 1)
        if earlier_slots:
            prev_word = (group_index << 6) + earlier_slots.bit_length() - 1
        else:
            earlier_groups = self.top & ((1 << group_index) - 1)
            if not earlier_groups:
                return 0
            prev_group = earlier_groups.bit_length() - 1
            prev_word = (prev_group << 6) + self.groups[prev_group].bit_length() - 1
        prev_bits = self.leaves[prev_word]
        return (prev_word << 6) + prev_bits.bit_length()


def expected_output(values: Sequence[int] | None, input_is_null: bool = False,
                    input_length: int | None = None) -> int:
    operations = _decode(values, input_length, input_is_null)
    if operations is None:
        return -1
    data = _BitmapSet()
    result = 0
    for operation_number, (opcode, key) in enumerate(operations, 1):
        if opcode == 0:
            answer = data.insert(key)
        elif opcode == 1:
            answer = data.erase(key)
        elif opcode == 2:
            answer = data.contains(key)
        elif opcode == 3:
            answer = data.successor(key)
        else:
            answer = data.predecessor(key)
        result += operation_number * answer
    return result
