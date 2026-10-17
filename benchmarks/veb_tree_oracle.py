"""Reference trace oracle for the bounded Van Emde Boas set workload."""

from __future__ import annotations

import struct

MAX_UNIVERSE = 256
MAX_COUNT = 256
MAX_INPUT_VALUES = 3 + MAX_COUNT + 2 * MAX_COUNT
MAX_OUTPUT_BYTES = 4 * MAX_COUNT


def _decompose(universe: int) -> tuple[int, int]:
    """Return (number of low bits, number of high clusters)."""
    exponent = universe.bit_length() - 1
    low_bits = exponent // 2
    low_size = 1 << low_bits
    return low_bits, universe // low_size


class _Node:
    __slots__ = ("universe", "low_bits", "cluster_count", "minimum", "maximum", "summary", "clusters")

    def __init__(self, universe: int) -> None:
        self.universe = universe
        self.minimum: int | None = None
        self.maximum: int | None = None
        if universe == 2:
            self.low_bits = 0
            self.cluster_count = 0
            self.summary = None
            self.clusters = []
        else:
            self.low_bits, self.cluster_count = _decompose(universe)
            low_size = 1 << self.low_bits
            self.summary = _Node(self.cluster_count)
            self.clusters = [_Node(low_size) for _ in range(self.cluster_count)]

    def _parts(self, value: int) -> tuple[int, int]:
        low_mask = (1 << self.low_bits) - 1
        return value >> self.low_bits, value & low_mask

    def contains(self, value: int) -> bool:
        if self.minimum is None:
            return False
        if value == self.minimum or value == self.maximum:
            return True
        if self.universe == 2:
            return False
        high, low = self._parts(value)
        return self.clusters[high].contains(low)

    def insert(self, value: int) -> None:
        if self.contains(value):
            return
        if self.minimum is None:
            self.minimum = self.maximum = value
            return
        if value < self.minimum:
            value, self.minimum = self.minimum, value
        if self.universe > 2:
            high, low = self._parts(value)
            cluster = self.clusters[high]
            if cluster.minimum is None:
                self.summary.insert(high)
                cluster.minimum = cluster.maximum = low
            else:
                cluster.insert(low)
        if value > self.maximum:
            self.maximum = value

    def successor(self, value: int) -> int | None:
        if self.minimum is None:
            return None
        if value < self.minimum:
            return self.minimum
        if self.universe == 2:
            return 1 if value == 0 and self.maximum == 1 else None
        high, low = self._parts(value)
        cluster = self.clusters[high]
        if cluster.maximum is not None and low < cluster.maximum:
            low_successor = cluster.successor(low)
            assert low_successor is not None
            return high * (1 << self.low_bits) + low_successor
        next_cluster = self.summary.successor(high)
        if next_cluster is None:
            return None
        next_minimum = self.clusters[next_cluster].minimum
        assert next_minimum is not None
        return next_cluster * (1 << self.low_bits) + next_minimum

    def predecessor(self, value: int) -> int | None:
        if self.minimum is None or value <= self.minimum:
            return None
        if value > self.maximum:
            return self.maximum
        if self.universe == 2:
            return 0 if value == 1 and self.minimum == 0 else None
        high, low = self._parts(value)
        cluster = self.clusters[high]
        if cluster.minimum is not None and low > cluster.minimum:
            low_predecessor = cluster.predecessor(low)
            assert low_predecessor is not None
            return high * (1 << self.low_bits) + low_predecessor
        previous_cluster = self.summary.predecessor(high)
        if previous_cluster is None:
            return self.minimum
        previous_maximum = self.clusters[previous_cluster].maximum
        assert previous_maximum is not None
        return previous_cluster * (1 << self.low_bits) + previous_maximum


def expected_output(
    values: list[int] | tuple[int, ...] | None,
    output_capacity: int | None = None,
    output_is_null: bool = False,
) -> tuple[int, bytes]:
    """Return (bytes_written_or_error, encoded query results)."""
    if (not isinstance(values, (list, tuple)) or len(values) < 3
            or len(values) > MAX_INPUT_VALUES
            or any(type(value) is not int or not -(2**63) <= value < 2**63
                   for value in values)):
        return -1, b""

    universe, insert_count, query_count = values[:3]
    if not 2 <= universe <= MAX_UNIVERSE:
        return -1, b""
    if not 0 <= insert_count <= MAX_COUNT or not 0 <= query_count <= MAX_COUNT:
        return -1, b""
    if len(values) != 3 + insert_count + 2 * query_count:
        return -1, b""

    inserted = values[3:3 + insert_count]
    queries = values[3 + insert_count:]
    if any(value < 0 or value >= universe for value in inserted):
        return -1, b""
    parsed: list[tuple[int, int]] = []
    for index in range(0, len(queries), 2):
        opcode, key = queries[index:index + 2]
        if opcode not in (0, 1, 2, 3, 4) or not 0 <= key < universe:
            return -1, b""
        parsed.append((opcode, key))

    needed = query_count * 4
    if needed > MAX_OUTPUT_BYTES:
        return -1, b""
    if output_is_null or (output_capacity is not None and output_capacity < needed):
        return -2, b""

    rounded_universe = 1 << (universe - 1).bit_length()
    tree = _Node(rounded_universe)
    for value in inserted:
        tree.insert(value)
    output = bytearray()
    for opcode, key in parsed:
        if opcode == 0:
            result = int(tree.contains(key))
        elif opcode == 1:
            result = tree.successor(key)
            result = -1 if result is None else result
        elif opcode == 2:
            result = tree.predecessor(key)
            result = -1 if result is None else result
        elif opcode == 3:
            result = 0xFFFFFFFF if tree.minimum is None else tree.minimum
        else:
            result = 0 if tree.maximum is None else tree.maximum
        if result is None:
            result = 0xFFFFFFFF
        output.extend(struct.pack("<I", result & 0xFFFFFFFF))
    return len(output), bytes(output)
