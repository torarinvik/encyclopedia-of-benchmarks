"""Node-and-branch model for a bounded cactus-stack operation trace."""

from __future__ import annotations

from collections.abc import Sequence

MAX_OPERATIONS = 48
HANDLE_COUNT = 8
MAX_VALUE = 1000
MIN_VALUE = -1000
MAX_VALID_INPUT_LENGTH = 1 + 3 * MAX_OPERATIONS
MAX_PARSEABLE_INPUT_LENGTH = MAX_VALID_INPUT_LENGTH + 1
MAX_OUTPUT_BYTES = 16 * MAX_OPERATIONS
WORKSPACE_BYTES = 4096
MAX_WORKSPACE_BYTES = WORKSPACE_BYTES
I64_MIN = -(1 << 63)
I64_MAX = (1 << 63) - 1


def _decode(values: Sequence[int] | None, input_length: int | None,
            input_is_null: bool) -> list[tuple[int, int, int]] | None:
    if type(input_is_null) is not bool or input_is_null:
        return None
    if not isinstance(values, (list, tuple)) or not 1 <= len(values) <= MAX_PARSEABLE_INPUT_LENGTH:
        return None
    if any(type(value) is not int or not I64_MIN <= value <= I64_MAX for value in values):
        return None
    declared = len(values) if input_length is None else input_length
    if type(declared) is not int or declared != len(values) or not 0 <= declared <= MAX_PARSEABLE_INPUT_LENGTH:
        return None
    q = values[0]
    if type(q) is not int or not 0 <= q <= MAX_OPERATIONS or len(values) != 1 + 3 * q:
        return None

    operations: list[tuple[int, int, int]] = []
    for i in range(q):
        op, a, b = values[1 + 3 * i:4 + 3 * i]
        if op == 0:
            if not 0 <= a < HANDLE_COUNT or not MIN_VALUE <= b <= MAX_VALUE:
                return None
        elif op in (1, 2, 3):
            if not 0 <= a < HANDLE_COUNT or b != 0:
                return None
        elif op == 4:
            if not 0 <= a < HANDLE_COUNT or not 0 <= b < HANDLE_COUNT:
                return None
        else:
            return None
        operations.append((op, a, b))
    return operations


def _run(operations: Sequence[tuple[int, int, int]]) -> list[tuple[int, int]] | None:
    # Node: [kind, value, next, child, live]. Kind 0 stores a value; kind 1
    # is a branch notch whose next link is the owner stack at attachment time.
    nodes: list[list[int]] = []
    heads = [-1] * HANDLE_COUNT
    branch_child = [-1] * HANDLE_COUNT
    attached_owner = [-1] * HANDLE_COUNT
    wrapper_for_child = [-1] * HANDLE_COUNT
    records: list[tuple[int, int]] = []

    def normalize(head: int) -> int:
        while head >= 0 and nodes[head][0] == 1 and nodes[head][4] == 0:
            head = nodes[head][2]
        return head

    def top_value(head: int) -> tuple[bool, int]:
        head = normalize(head)
        while head >= 0 and nodes[head][0] == 1:
            head = normalize(nodes[head][2])
        if head < 0:
            return False, 0
        return True, nodes[head][1]

    for op, a, b in operations:
        head = normalize(heads[a])
        heads[a] = head
        if op == 0:
            nodes.append([0, b, head, -1, 0])
            heads[a] = len(nodes) - 1
            records.append((1, 0))
        elif op == 1:
            if head < 0 or (nodes[head][0] == 1 and nodes[head][4] != 0):
                records.append((0, 0))
                continue
            popped = nodes[head][1]
            heads[a] = normalize(nodes[head][2])
            if heads[a] < 0 and attached_owner[a] >= 0:
                owner = attached_owner[a]
                wrapper = wrapper_for_child[a]
                nodes[wrapper][4] = 0
                branch_child[owner] = -1
                attached_owner[a] = -1
                wrapper_for_child[a] = -1
            records.append((1, popped))
        elif op == 2:
            exists, value = top_value(head)
            records.append((1 if exists else 0, value if exists else 0))
        elif op == 3:
            is_notch = head >= 0 and nodes[head][0] == 1 and nodes[head][4] != 0
            records.append((1, 1 if is_notch else 0))
        else:
            child = b
            child_head = normalize(heads[child])
            heads[child] = child_head
            owner_nonempty, _ = top_value(head)
            if (a == child or not owner_nonempty or attached_owner[a] >= 0
                    or branch_child[a] >= 0 or attached_owner[child] >= 0
                    or branch_child[child] >= 0):
                return None
            if child_head < 0:
                records.append((1, 0))
                continue
            nodes.append([1, 0, head, child, 1])
            wrapper = len(nodes) - 1
            heads[a] = wrapper
            branch_child[a] = child
            attached_owner[child] = a
            wrapper_for_child[child] = wrapper
            records.append((1, 1))
    return records


def expected_output(
    values: Sequence[int] | None,
    capacity: int | None = None,
    output_is_null: bool = False,
    input_is_null: bool = False,
    input_length: int | None = None,
) -> tuple[int, bytes]:
    operations = _decode(values, input_length, input_is_null)
    if operations is None:
        return -1, b""
    records = _run(operations)
    if records is None:
        return -1, b""
    if type(output_is_null) is not bool:
        return -2, b""
    if capacity is not None and (type(capacity) is not int or capacity < 0):
        return -2, b""
    payload = b"".join(
        (status & ((1 << 64) - 1)).to_bytes(8, "little")
        + (value & ((1 << 64) - 1)).to_bytes(8, "little")
        for status, value in records
    )
    if output_is_null or (capacity is not None and capacity < len(payload)):
        return -2, b""
    return len(payload), payload
