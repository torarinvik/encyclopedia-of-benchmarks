"""Oracle for the bounded recursive simultaneous-equation solver."""

from collections.abc import Sequence
import math
import struct

MIN_EQUATIONS = 1
MAX_EQUATIONS = 5
MIN_COEFFICIENT = -100_000
MAX_COEFFICIENT = 100_000
MAX_INPUT_LENGTH = 1 + MAX_EQUATIONS * (MAX_EQUATIONS + 1)
MAX_OUTPUT_BYTES = 8 * (1 + MAX_EQUATIONS)
SCALE = 1_000
TICK_SCALE = 100_000
MAX_TICK_MAGNITUDE = 1 << 51
INVALID_RESULT = -1
CAPACITY_ERROR = -2
I64_MIN = -(1 << 63)
I64_MAX = (1 << 63) - 1


def _finite_rows(rows: list[list[float]]) -> bool:
    return all(math.isfinite(value) for row in rows for value in row)


def _simplify(rows: list[list[float]]) -> list[list[float]] | None:
    if not rows or not rows[0] or rows[0][0] == 0.0:
        return None

    current = [row[:] for row in rows]
    for row in current:
        magnitude = row[0]
        if magnitude != 0.0:
            for col in range(len(row)):
                row[col] /= magnitude
    if not _finite_rows(current):
        return None

    first_row = current[0][:]
    final_rows = [first_row]
    for row in current[1:]:
        if row[0] == 0.0:
            final_rows.append(row[:])
        else:
            final_rows.append([first_row[col] - row[col] for col in range(len(row))])
    if not _finite_rows(final_rows):
        return None

    if len(final_rows[0]) != 3:
        first_column = [row[0] for row in final_rows[1:]]
        next_rows = [row[1:] for row in final_rows[1:]]
        reduced = _simplify(next_rows)
        if reduced is None or len(reduced) != len(first_column):
            return None
        for index, row in enumerate(reduced):
            row.insert(0, first_column[index])
        final_rows = [first_row, *reduced]
    return final_rows


def expected_output(values: Sequence[int], capacity: int | None = None) -> tuple[int, bytes]:
    if (not isinstance(values, (list, tuple)) or not 2 <= len(values) <= MAX_INPUT_LENGTH
            or any(type(value) is not int or not I64_MIN <= value <= I64_MAX for value in values)):
        return INVALID_RESULT, b""
    n = values[0]
    if not MIN_EQUATIONS <= n <= MAX_EQUATIONS or len(values) != 1 + n * (n + 1):
        return INVALID_RESULT, b""
    coefficients = values[1:]
    if any(value < MIN_COEFFICIENT or value > MAX_COEFFICIENT for value in coefficients):
        return INVALID_RESULT, b""
    equations = [
        [coefficients[row * (n + 1) + col] / SCALE for col in range(n + 1)]
        for row in range(n)
    ]
    if n == 1:
        if equations[0][0] == 0.0:
            return INVALID_RESULT, b""
        solutions = [equations[0][1] / equations[0][0]]
    else:
        # Match the source's one-time search for a row with no zero entries.
        if any(0.0 in row for row in equations):
            full_row = next((index for index, row in enumerate(equations)
                             if all(value != 0.0 for value in row)), None)
            if full_row is None:
                return INVALID_RESULT, b""
            equations.insert(0, equations.pop(full_row))

        simplified = _simplify(equations)
        if simplified is None or len(simplified) != n:
            return INVALID_RESULT, b""

        reverse_solutions: list[float] = []
        for row in reversed(simplified):
            current_solution = row[-1]
            if not reverse_solutions:
                pivot = row[-2]
                if pivot == 0.0:
                    return INVALID_RESULT, b""
                current_solution /= pivot
                reverse_solutions.append(current_solution)
                continue

            terms = row[:-1]
            while terms and terms[0] == 0.0:
                terms.pop(0)
            if not terms:
                return INVALID_RESULT, b""
            terms = list(reversed(terms[1:]))
            if len(terms) != len(reverse_solutions):
                return INVALID_RESULT, b""
            for index, coefficient in enumerate(terms):
                current_solution -= coefficient * reverse_solutions[index]
            reverse_solutions.append(current_solution)
        solutions = list(reversed(reverse_solutions))

    if not all(math.isfinite(value) for value in solutions):
        return INVALID_RESULT, b""
    # Preserve the source's decimal-digit rounding before projecting each value to a tick.
    rounded = [float(round(value, 5)) for value in solutions]
    ticks: list[int] = []
    for value in rounded:
        scaled = value * TICK_SCALE
        if not math.isfinite(scaled):
            return INVALID_RESULT, b""
        tick = int(round(scaled))
        if not I64_MIN <= tick <= I64_MAX or abs(tick) > MAX_TICK_MAGNITUDE:
            return INVALID_RESULT, b""
        ticks.append(tick)

    output = struct.pack("<q", n) + b"".join(struct.pack("<q", tick) for tick in ticks)
    if capacity is not None and (type(capacity) is not int or capacity < len(output)):
        return CAPACITY_ERROR, b""
    return len(output), output
