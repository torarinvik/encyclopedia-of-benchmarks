"""Scalar operation-tape contract for the pinned reverse-mode autodiff source."""

from __future__ import annotations

import math

INVALID_RESULT = -1e300
MAX_LEAVES = 32
MAX_OPERATIONS = 64


def automatic_differentiation(values: list[int]) -> float:
    """Return d(target)/d(source) for a bounded scalar operation tape.

    Each operation produces one new node and may only read prior nodes. The
    supported operations are add, subtract, multiply, divide, and integer power.
    """
    if (not isinstance(values, list) or len(values) < 7
            or any(type(value) is not int or not -(1 << 63) <= value < (1 << 63)
                   for value in values)):
        return INVALID_RESULT
    leaf_count, operation_count, target, source = values[:4]
    if (not 1 <= leaf_count <= MAX_LEAVES or not 1 <= operation_count <= MAX_OPERATIONS
            or len(values) != 4 + leaf_count + 3 * operation_count
            or not leaf_count <= target < leaf_count + operation_count
            or not 0 <= source < leaf_count):
        return INVALID_RESULT
    leaves = values[4:4 + leaf_count]
    if any(not -16 <= value <= 16 for value in leaves):
        return INVALID_RESULT

    nodes: list[int | float] = list(leaves)
    operations: list[tuple[int, int, int]] = []
    offset = 4 + leaf_count
    for operation_index in range(operation_count):
        opcode, left, right = values[offset:offset + 3]
        output_node = leaf_count + operation_index
        if opcode not in (0, 1, 2, 3, 5) or not 0 <= left < output_node:
            return INVALID_RESULT
        if opcode == 5:
            if not 1 <= right <= 8:
                return INVALID_RESULT
            right_value = 0
            result = nodes[left] ** right
        else:
            if not 0 <= right < output_node:
                return INVALID_RESULT
            right_value = right
            left_value, right_operand = nodes[left], nodes[right]
            if opcode == 0:
                result = left_value + right_operand
            elif opcode == 1:
                result = left_value - right_operand
            elif opcode == 2:
                result = left_value * right_operand
            else:
                if right_operand == 0:
                    return INVALID_RESULT
                result = left_value / right_operand
        if not math.isfinite(float(result)) or abs(result) > 10_000_000_000:
            return INVALID_RESULT
        nodes.append(result)
        operations.append((opcode, left, right_value if opcode != 5 else right))
        offset += 3

    # Reverse accumulation over this topologically ordered scalar DAG.
    adjoints = [0.0] * len(nodes)
    ancestors = [False] * len(nodes)
    adjoints[target] = 1.0
    ancestors[target] = True
    for operation_index in range(target - leaf_count, -1, -1):
        output_node = leaf_count + operation_index
        if not ancestors[output_node]:
            continue
        opcode, left, right = operations[operation_index]
        adjoint = adjoints[output_node]
        ancestors[left] = True
        if opcode == 0:
            adjoints[left] += adjoint
            ancestors[right] = True
            adjoints[right] += adjoint
        elif opcode == 1:
            adjoints[left] += adjoint
            ancestors[right] = True
            adjoints[right] -= adjoint
        elif opcode == 2:
            ancestors[right] = True
            adjoints[left] += adjoint * float(nodes[right])
            adjoints[right] += adjoint * float(nodes[left])
        elif opcode == 3:
            ancestors[right] = True
            left_value, right_value = float(nodes[left]), float(nodes[right])
            adjoints[left] += adjoint / right_value
            adjoints[right] += adjoint * (-left_value / (right_value * right_value))
        else:  # integer power
            exponent = right
            adjoints[left] += adjoint * exponent * float(nodes[left]) ** (exponent - 1)
    if not ancestors[source]:
        return INVALID_RESULT
    result = adjoints[source]
    return result if math.isfinite(result) and abs(result) <= 1e300 else INVALID_RESULT

