"""Independent verifier using clause truth masks and separate trace state."""

from __future__ import annotations

from collections.abc import Sequence

MAX_INPUT_LENGTH = 39


def _decode(values: Sequence[int] | None) -> tuple[int, int, list[tuple[int, ...]]] | None:
    if (not isinstance(values, (tuple, list)) or len(values) < 3 or len(values) > MAX_INPUT_LENGTH
            or any(type(v) is not int or not -(1 << 63) <= v < (1 << 63) for v in values)):
        return None
    n, m, k = values[0], values[1], values[2]
    if not 1 <= n <= 5 or not 0 <= m <= 6 or not 1 <= k <= n:
        return None
    clauses: list[tuple[int, ...]] = []
    cursor = 3
    for _ in range(m):
        if cursor == len(values):
            return None
        width = values[cursor]
        cursor += 1
        if not 1 <= width <= n or cursor + width > len(values):
            return None
        literals = tuple(values[cursor:cursor + width])
        cursor += width
        if any(lit == 0 or abs(lit) > n for lit in literals):
            return None
        variable_mask = sum(1 << (abs(lit) - 1) for lit in literals)
        if variable_mask.bit_count() != width:
            return None
        clauses.append(literals)
    if cursor != len(values):
        return None
    return n, k, clauses


def _clause_true(literals: tuple[int, ...], assignment: int) -> bool:
    positive = 0
    negative = 0
    for lit in literals:
        bit = 1 << (abs(lit) - 1)
        if lit > 0:
            positive |= bit
        else:
            negative |= bit
    return bool((positive & assignment) | (negative & ~assignment))


def evaluate(values: Sequence[int] | None) -> tuple[int, bytes]:
    decoded = _decode(values)
    if decoded is None:
        return -1, b""
    n, k, clauses = decoded
    trace = {"calls": 0, "checks": 0, "branches": 0, "depth": 0}

    def visit(current: list[tuple[int, ...]], fixed: int, fixed_mask: int, level: int) -> int | None:
        trace["calls"] += 1
        trace["depth"] = max(trace["depth"], level)
        abbreviated = [clause[:k] for clause in current]
        trace["checks"] += 1
        for encoded in range(1 << n):
            candidate = 0
            for bit_index in range(n):
                if (encoded >> (n - bit_index - 1)) & 1:
                    candidate |= 1 << bit_index
            if (candidate ^ fixed) & fixed_mask:
                continue
            if all(_clause_true(clause, candidate) for clause in abbreviated):
                return candidate
        for ordinal, chosen_prefix in enumerate(abbreviated):
            if len(chosen_prefix) == 0:
                continue
            trace["branches"] += 1
            assignment = fixed
            assigned_bits = fixed_mask
            for lit in chosen_prefix:
                bit = 1 << (abs(lit) - 1)
                if lit > 0:
                    assignment &= ~bit
                else:
                    assignment |= bit
                assigned_bits |= bit
            delta = assigned_bits & ~fixed_mask
            descendants: list[tuple[int, ...]] = []
            for ci, clause in enumerate(current):
                portion = abbreviated[ci] if ci < ordinal else clause
                remains: list[int] = []
                fulfilled = False
                for lit in portion:
                    bit = 1 << (abs(lit) - 1)
                    if delta & bit:
                        bit_value = bool(assignment & bit)
                        if (lit > 0 and bit_value) or (lit < 0 and not bit_value):
                            fulfilled = True
                            break
                    else:
                        remains.append(lit)
                if not fulfilled:
                    descendants.append(tuple(remains))
            found = visit(descendants, assignment, assigned_bits, level + 1)
            if found is not None:
                return found
        return None

    assignment = visit(clauses, 0, 0, 0)
    fields = [1 if assignment is not None else 0, assignment or 0,
              trace["calls"], trace["checks"], trace["branches"], trace["depth"]]
    output = b"".join(int(field).to_bytes(8, "little", signed=True) for field in fields)
    return len(output), output


def expected_output(values: Sequence[int] | None, capacity: int | None = None,
                    output_is_null: bool = False, input_is_null: bool = False,
                    input_length: int | None = None) -> tuple[int, bytes]:
    if (type(output_is_null) is not bool or type(input_is_null) is not bool
            or capacity is not None and (type(capacity) is not int or capacity < 0)
            or input_length is not None and (type(input_length) is not int
                                             or not 0 <= input_length <= MAX_INPUT_LENGTH)
            or input_is_null and values not in (None, [], ())
            or not input_is_null and values is not None and input_length is not None
            and input_length != len(values)):
        return -1, b""
    if input_is_null or values is None:
        return -1, b""
    status, data = evaluate(values)
    if status < 0:
        return status, data
    if output_is_null or capacity is not None and capacity < len(data):
        return -2, b""
    return status, data
