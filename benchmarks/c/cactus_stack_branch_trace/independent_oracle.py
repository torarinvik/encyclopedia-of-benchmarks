"""Copied-vector semantics for a bounded cactus-stack trace."""

from __future__ import annotations

from collections.abc import Sequence

MAX_OPERATIONS = 48
HANDLE_COUNT = 8
MAX_VALID_INPUT_LENGTH = 145
MAX_PARSEABLE_INPUT_LENGTH = 146
MAX_VALUE = 1000
MIN_VALUE = -1000
MAX_OUTPUT_BYTES = 768
WORKSPACE_BYTES = 4096
MAX_WORKSPACE_BYTES = WORKSPACE_BYTES
I64_MIN = -(1 << 63)
I64_MAX = (1 << 63) - 1


def _decode(values: Sequence[int] | None, input_length: int | None,
            input_is_null: bool) -> list[tuple[int, int, int]] | None:
    if type(input_is_null) is not bool or input_is_null or not isinstance(values, (list, tuple)):
        return None
    if not 1 <= len(values) <= MAX_PARSEABLE_INPUT_LENGTH:
        return None
    if any(type(x) is not int or x < I64_MIN or x > I64_MAX for x in values):
        return None
    declared = len(values) if input_length is None else input_length
    if type(declared) is not int or declared != len(values) or not 0 <= declared <= MAX_PARSEABLE_INPUT_LENGTH:
        return None
    q = values[0]
    if type(q) is not int or not 0 <= q <= MAX_OPERATIONS or len(values) != 1 + 3 * q:
        return None
    ops = []
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
        ops.append((op, a, b))
    return ops


def _copy_model(ops: Sequence[tuple[int, int, int]]) -> list[tuple[int, int]] | None:
    stacks: list[list[int]] = [[] for _ in range(HANDLE_COUNT)]
    child_for_owner = [-1] * HANDLE_COUNT
    owner_for_child = [-1] * HANDLE_COUNT
    branch_depth = [-1] * HANDLE_COUNT
    records: list[tuple[int, int]] = []

    for op, a, b in ops:
        stack = stacks[a]
        if op == 0:
            stack.append(b)
            records.append((1, 0))
        elif op == 1:
            at_live_notch = branch_depth[a] >= 0 and len(stack) == branch_depth[a]
            if not stack or at_live_notch:
                records.append((0, 0))
                continue
            value = stack.pop()
            if not stack and owner_for_child[a] >= 0:
                owner = owner_for_child[a]
                child_for_owner[owner] = -1
                branch_depth[owner] = -1
                owner_for_child[a] = -1
            records.append((1, value))
        elif op == 2:
            records.append((1, stack[-1]) if stack else (0, 0))
        elif op == 3:
            notch = branch_depth[a] >= 0 and len(stack) == branch_depth[a]
            records.append((1, 1 if notch else 0))
        else:
            child = b
            if (a == child or not stack or owner_for_child[a] >= 0
                    or child_for_owner[a] >= 0 or owner_for_child[child] >= 0
                    or child_for_owner[child] >= 0):
                return None
            if not stacks[child]:
                records.append((1, 0))
                continue
            child_for_owner[a] = child
            owner_for_child[child] = a
            branch_depth[a] = len(stack)
            records.append((1, 1))
    return records


def expected_output(values: Sequence[int] | None, capacity: int | None = None,
                    output_is_null: bool = False, input_is_null: bool = False,
                    input_length: int | None = None) -> tuple[int, bytes]:
    ops = _decode(values, input_length, input_is_null)
    if ops is None:
        return -1, b""
    records = _copy_model(ops)
    if records is None:
        return -1, b""
    if type(output_is_null) is not bool:
        return -2, b""
    if capacity is not None and (type(capacity) is not int or capacity < 0):
        return -2, b""
    payload = b"".join(
        int(field & ((1 << 64) - 1)).to_bytes(8, "little")
        for record in records for field in record
    )
    if output_is_null or (capacity is not None and capacity < len(payload)):
        return -2, b""
    return len(payload), payload
