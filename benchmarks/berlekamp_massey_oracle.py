"""Independent bounded Gaussian-elimination oracle for recurrence inference."""

import struct

MODULUS = 998_244_353
MAX_ORDER_BOUND = 8
MAX_VALID_INPUT_LENGTH = 1 + 2 * MAX_ORDER_BOUND
MAX_PARSEABLE_INPUT_LENGTH = MAX_VALID_INPUT_LENGTH + 1
MAX_OUTPUT_BYTES = 8 * (MAX_ORDER_BOUND + 1)


def _solve_order(sequence, order):
    """Return the unique predictive recurrence of ``order``, or ``None``."""
    if order == 0:
        return [] if all(value == 0 for value in sequence) else None

    rows = []
    for index in range(order, len(sequence)):
        rows.append([
            sequence[index - lag - 1] for lag in range(order)
        ] + [sequence[index]])

    rank = 0
    pivot_columns = []
    for column in range(order):
        pivot = next((row for row in range(rank, len(rows))
                      if rows[row][column] != 0), None)
        if pivot is None:
            continue
        rows[rank], rows[pivot] = rows[pivot], rows[rank]
        inverse = pow(rows[rank][column], MODULUS - 2, MODULUS)
        rows[rank] = [(value * inverse) % MODULUS for value in rows[rank]]
        for row in range(len(rows)):
            if row == rank or rows[row][column] == 0:
                continue
            factor = rows[row][column]
            rows[row] = [
                (value - factor * pivot_value) % MODULUS
                for value, pivot_value in zip(rows[row], rows[rank])
            ]
        pivot_columns.append(column)
        rank += 1

    if any(all(value == 0 for value in row[:order]) and row[order] != 0
           for row in rows):
        return None
    if rank != order:
        return None

    coefficients = [0] * order
    for row, column in enumerate(pivot_columns):
        coefficients[column] = rows[row][order]
    return coefficients


def _shortest_unique_recurrence(sequence, order_bound):
    for order in range(order_bound + 1):
        coefficients = _solve_order(sequence, order)
        if coefficients is not None:
            return order, coefficients
    return None


def expected_output(values, capacity=None, output_is_null=False,
                    input_is_null=False, input_length=None):
    """Return ``(status, bytes)`` for ``[K, a_0, ..., a_(2K-1)]``."""
    if input_is_null or not isinstance(values, (list, tuple)):
        return -1, b""
    if input_length is None:
        input_length = len(values)
    if (type(input_length) is not int or input_length != len(values)
            or input_length < 2 or input_length > MAX_PARSEABLE_INPUT_LENGTH
            or any(type(value) is not int for value in values)):
        return -1, b""

    order_bound = values[0]
    if not 1 <= order_bound <= MAX_ORDER_BOUND:
        return -1, b""
    if len(values) != 1 + 2 * order_bound:
        return -1, b""
    sequence = values[1:]
    if any(not 0 <= value < MODULUS for value in sequence):
        return -1, b""

    recurrence = _shortest_unique_recurrence(sequence, order_bound)
    if recurrence is None:
        return -1, b""
    order, coefficients = recurrence
    encoded = struct.pack("<q", order) + b"".join(
        struct.pack("<q", coefficient) for coefficient in coefficients
    )

    effective_capacity = MAX_OUTPUT_BYTES if capacity is None else capacity
    if (type(output_is_null) is not bool or type(effective_capacity) is not int
            or effective_capacity < 0):
        return -2, b""
    if output_is_null or effective_capacity < len(encoded):
        return -2, b""
    return len(encoded), encoded
