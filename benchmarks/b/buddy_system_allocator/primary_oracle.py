"""Free-list reference for a bounded buddy-system allocation trace."""

from __future__ import annotations

from collections.abc import Sequence

ARENA_UNITS = 256
MAX_OPERATIONS = 64
MAX_IDS = 32
MAX_INPUT_LENGTH = 1 + 3 * MAX_OPERATIONS + 1
MAX_FREE_BLOCKS = ARENA_UNITS
MAX_OUTPUT_BYTES = (3 * MAX_OPERATIONS + 1 + 2 * MAX_FREE_BLOCKS) * 8
WORKSPACE_BYTES = 16_384
MAX_ORDER = 8


def _decode(values: Sequence[int] | None):
    if not isinstance(values, (list, tuple)) or not 1 <= len(values) <= MAX_INPUT_LENGTH:
        return None
    if any(type(value) is not int or value < -(1 << 63) or value >= (1 << 63) for value in values):
        return None
    count = values[0]
    if not 0 <= count <= MAX_OPERATIONS or len(values) != 1 + 3 * count:
        return None
    operations: list[tuple[int, int, int]] = []
    for index in range(count):
        opcode, tag, argument = values[1 + 3 * index:4 + 3 * index]
        if opcode == 0:
            if not 0 <= tag < MAX_IDS or not 1 <= argument <= ARENA_UNITS:
                return None
        elif opcode == 1:
            if not 0 <= tag < MAX_IDS or argument != 0:
                return None
        else:
            return None
        operations.append((opcode, tag, argument))
    return operations


def _round_order(size: int) -> int:
    order = 0
    block_size = 1
    while block_size < size:
        order += 1
        block_size <<= 1
    return order


def _run_freelists(operations: list[tuple[int, int, int]]):
    free = [[False] * ARENA_UNITS for _ in range(MAX_ORDER + 1)]
    free[MAX_ORDER][0] = True
    active = [False] * MAX_IDS
    bases = [0] * MAX_IDS
    orders = [0] * MAX_IDS
    trace: list[int] = []

    for opcode, tag, argument in operations:
        if opcode == 0:
            if active[tag]:
                return None
            target = _round_order(argument)
            selected_order = -1
            selected_base = -1
            for order in range(target, MAX_ORDER + 1):
                size = 1 << order
                for base in range(0, ARENA_UNITS - size + 1, size):
                    if free[order][base]:
                        selected_order = order
                        selected_base = base
                        break
                if selected_order >= 0:
                    break
            if selected_order < 0:
                trace.extend((0, -1, 0))
                continue
            free[selected_order][selected_base] = False
            while selected_order > target:
                selected_order -= 1
                upper = selected_base + (1 << selected_order)
                free[selected_order][upper] = True
            active[tag] = True
            bases[tag] = selected_base
            orders[tag] = target
            trace.extend((1, selected_base, 1 << target))
        else:
            if not active[tag]:
                return None
            base = bases[tag]
            order = orders[tag]
            released_size = 1 << order
            active[tag] = False
            while order < MAX_ORDER:
                buddy = base ^ (1 << order)
                if not free[order][buddy]:
                    break
                free[order][buddy] = False
                base = min(base, buddy)
                order += 1
            free[order][base] = True
            trace.extend((1, bases[tag], released_size))

    blocks: list[tuple[int, int]] = []
    for base in range(ARENA_UNITS):
        for order in range(MAX_ORDER, -1, -1):
            if free[order][base]:
                blocks.append((base, 1 << order))
                break
    return trace, blocks


def _serialize(trace: list[int], blocks: list[tuple[int, int]]) -> bytes:
    words = trace + [len(blocks)]
    for base, size in blocks:
        words.extend((base, size))
    return b"".join((word & ((1 << 64) - 1)).to_bytes(8, "little") for word in words)


def expected_output(values: Sequence[int] | None, capacity: int | None = None,
                    output_is_null: bool = False, input_is_null: bool = False,
                    input_length: int | None = None) -> tuple[int, bytes]:
    if type(output_is_null) is not bool or type(input_is_null) is not bool:
        return -1, b""
    if capacity is not None and (type(capacity) is not int or capacity < 0):
        return -1, b""
    if input_length is not None and (type(input_length) is not int or not 0 <= input_length <= MAX_INPUT_LENGTH):
        return -1, b""
    if input_is_null or values is None or not isinstance(values, (list, tuple)):
        return -1, b""
    if input_length is not None and input_length != len(values):
        return -1, b""
    operations = _decode(values)
    if operations is None:
        return -1, b""
    result = _run_freelists(operations)
    if result is None:
        return -1, b""
    output = _serialize(*result)
    if output_is_null or capacity is not None and capacity < len(output):
        return -2, b""
    return len(output), output
