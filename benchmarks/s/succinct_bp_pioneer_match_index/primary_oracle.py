"""Bounded recursive pioneer-family index for balanced-parenthesis matching."""

from __future__ import annotations

import struct

MAX_PAIRS = 32
MAX_BITS = 2 * MAX_PAIRS
MAX_VALID_INPUT_LENGTH = 1 + MAX_BITS
MAX_PARSEABLE_INPUT_LENGTH = MAX_VALID_INPUT_LENGTH + 1
MAX_OUTPUT_BYTES = 8 * (1 + MAX_BITS)
WORKSPACE_BYTES = 8192
BLOCK_SIZE = 8
BASE_BITS = 16


def _decode(values, input_is_null=False, input_length=None):
    if (type(input_is_null) is not bool or input_is_null
            or not isinstance(values, (tuple, list))
            or len(values) > MAX_PARSEABLE_INPUT_LENGTH
            or any(type(value) is not int or not -(1 << 63) <= value < (1 << 63)
                   for value in values)):
        return None
    if input_length is not None and (type(input_length) is not int or input_length != len(values)):
        return None
    if not values or not 1 <= values[0] <= MAX_PAIRS:
        return None
    pairs = values[0]
    if len(values) != 1 + 2 * pairs:
        return None
    bits = list(values[1:])
    if any(bit not in (0, 1) for bit in bits):
        return None
    depth = 0
    for bit in bits:
        depth += 1 if bit else -1
        if depth < 0:
            return None
    if depth != 0:
        return None
    return bits


def _matching(bits):
    mate = [-1] * len(bits)
    stack = []
    for position, bit in enumerate(bits):
        if bit:
            stack.append(position)
        else:
            opening = stack.pop()
            mate[opening] = position
            mate[position] = opening
    return mate


class _Index:
    """Fixed-profile block index with recursive pioneer-family matching."""

    def __init__(self, bits):
        self.bits = bits
        self.length = len(bits)
        matched = _matching(bits)  # Temporary stack map; never retained for far queries.
        self.mate = [-1] * self.length
        self.far = [False] * self.length
        self.depth = [0] * (self.length + 1)
        for position, bit in enumerate(bits):
            self.depth[position + 1] = self.depth[position] + (1 if bit else -1)
        self.child = None
        self.family = []
        self.family_rank = [-1] * self.length
        self.open_pioneers = []
        self.close_pioneers = []
        self.open_groups = {}
        self.close_groups = {}
        if self.length <= BASE_BITS:
            self.mate = matched
            return

        far = [False] * self.length
        for position in range(self.length):
            target_block = matched[position] // BLOCK_SIZE
            if target_block != position // BLOCK_SIZE:
                far[position] = True
                self.far[position] = True
                # The destination is a grouping key only. Queries recover their
                # target block recursively from a pioneer instead of consulting
                # a stored per-position destination.
                group = (position // BLOCK_SIZE, target_block,
                         self.depth[position] if bits[position] else self.depth[position + 1])
                groups = self.open_groups if bits[position] else self.close_groups
                groups.setdefault(group, []).append(position)
            else:
                self.mate[position] = matched[position]

        previous_target = {}
        for position, bit in enumerate(bits):
            if not bit or not far[position]:
                continue
            block = position // BLOCK_SIZE
            target = matched[position] // BLOCK_SIZE
            prior = previous_target.get(block)
            if prior is None or prior != target:
                self.open_pioneers.append(position)
            previous_target[block] = target

        following_target = {}
        for position in range(self.length - 1, -1, -1):
            if bits[position] or not far[position]:
                continue
            block = position // BLOCK_SIZE
            target = matched[position] // BLOCK_SIZE
            following = following_target.get(block)
            if following is None or following != target:
                self.close_pioneers.append(position)
            following_target[block] = target
        self.close_pioneers.sort()

        family = set()
        for position in self.open_pioneers + self.close_pioneers:
            family.add(position)
            family.add(matched[position])
        self.family = sorted(family)
        for rank, position in enumerate(self.family):
            self.family_rank[position] = rank
        if len(self.family) >= self.length:
            raise ValueError("pioneer-family recursion did not shrink")
        self.child = _Index([bits[position] for position in self.family])

    def match(self, position):
        if self.length <= BASE_BITS:
            return self.mate[position]
        if not self.far[position]:
            return self.mate[position]

        source_block = position // BLOCK_SIZE
        if self.bits[position]:
            pioneer = -1
            for candidate in self.open_pioneers:
                if candidate // BLOCK_SIZE == source_block and candidate <= position:
                    pioneer = candidate
                elif candidate // BLOCK_SIZE > source_block:
                    break
            if pioneer < 0:
                raise ValueError("far opening has no block pioneer")
            child_match = self.child.match(self.family_rank[pioneer])
            anchor = self.family[child_match]
            target_block = anchor // BLOCK_SIZE
            relative_excess = self.depth[position] - self.depth[pioneer]
            target_depth = self.depth[pioneer] + relative_excess
            opens = self.open_groups[(source_block, target_block, target_depth)]
            closes = self.close_groups[(target_block, source_block, target_depth)]
            return closes[opens.index(position)]

        pioneer = -1
        for candidate in self.close_pioneers:
            if candidate // BLOCK_SIZE == source_block and candidate >= position:
                pioneer = candidate
                break
        if pioneer < 0:
            raise ValueError("far closing has no block pioneer")
        child_match = self.child.match(self.family_rank[pioneer])
        anchor = self.family[child_match]
        target_block = anchor // BLOCK_SIZE
        relative_excess = self.depth[position + 1] - self.depth[pioneer + 1]
        target_depth = self.depth[pioneer + 1] + relative_excess
        closes = self.close_groups[(source_block, target_block, target_depth)]
        opens = self.open_groups[(target_block, source_block, target_depth)]
        return opens[closes.index(position)]


def expected_output(values, output_capacity=None, output_is_null=False,
                    input_is_null=False, input_length=None):
    bits = _decode(values, input_is_null, input_length)
    if bits is None or type(output_is_null) is not bool:
        return -1, b""
    required = 8 * (1 + len(bits))
    if output_is_null or (output_capacity is not None and
                          (type(output_capacity) is not int or output_capacity < required)):
        return -2, b""
    index = _Index(bits)
    words = [len(bits)] + [index.match(position) for position in range(len(bits))]
    return required, b"".join(struct.pack("<q", word) for word in words)


def expected_result(values, output_capacity=None, output_is_null=False,
                    input_is_null=False, input_length=None):
    return expected_output(values, output_capacity, output_is_null,
                          input_is_null, input_length)[0]
