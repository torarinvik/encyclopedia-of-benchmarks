"""Independent immutable-formula oracle for the bounded CL trace."""

from __future__ import annotations

import struct
from collections import Counter
from collections.abc import Sequence

MAX_VARS = 8
MAX_CLAUSES = 24
MAX_INPUT_LENGTH = 98
MAX_PARSEABLE_INPUT_LENGTH = 99
MAX_OUTPUT_BYTES = 352
WORKSPACE_BYTES = 16_384


def _parse(frame: Sequence[int] | None) -> tuple[int, tuple[tuple[int, ...], ...]] | None:
    if not isinstance(frame, (list, tuple)) or not 2 <= len(frame) <= MAX_PARSEABLE_INPUT_LENGTH:
        return None
    if any(type(word) is not int or not -(1 << 63) <= word < (1 << 63) for word in frame):
        return None
    n, m = frame[:2]
    if not 1 <= n <= MAX_VARS or not 0 <= m <= MAX_CLAUSES or len(frame) != 2 + 4 * m:
        return None
    clauses: list[tuple[int, ...]] = []
    for start in range(2, len(frame), 4):
        size, *slots = frame[start:start + 4]
        clause = tuple(slots[:size]) if type(size) is int and 1 <= size <= 3 else ()
        if (not clause or any(type(lit) is not int or lit == 0 or abs(lit) > n for lit in clause)
                or len({abs(lit) for lit in clause}) != len(clause)
                or any(slots[i] != 0 for i in range(size, 3))):
            return None
        clauses.append(clause)
    return n, tuple(clauses)


def _simplify(formula: tuple[tuple[int, ...], ...], values: tuple[int, ...], literal: int
              ) -> tuple[tuple[tuple[int, ...], ...], tuple[int, ...]] | None:
    index = abs(literal) - 1
    sign = 1 if literal > 0 else -1
    if values[index] and values[index] != sign:
        return None
    next_values = values[:index] + (sign,) + values[index + 1:]
    next_formula: list[tuple[int, ...]] = []
    for clause in formula:
        if any(part == literal for part in clause):
            continue
        rest = tuple(part for part in clause if part != -literal)
        if not rest:
            return None
        next_formula.append(rest)
    return tuple(next_formula), next_values


def _force(formula: tuple[tuple[int, ...], ...], values: tuple[int, ...],
           log: list[tuple[int, int, int, int]]) -> tuple[tuple[tuple[int, ...], ...] | None,
                                                              tuple[int, ...]]:
    while True:
        unit = next((clause[0] for clause in formula if len(clause) == 1), 0)
        if unit == 0:
            return formula, values
        log.append((unit, 1, -1, -1))
        index = abs(unit) - 1
        sign = 1 if unit > 0 else -1
        attempted_values = values[:index] + (sign,) + values[index + 1:]
        reduced = _simplify(formula, values, unit)
        if reduced is None:
            return None, attempted_values
        formula, values = reduced


def _degrees(formula: tuple[tuple[int, ...], ...]) -> Counter[int]:
    counts: Counter[int] = Counter()
    for clause in formula:
        counts.update(clause)
    return counts


def _members(n: int, formula: tuple[tuple[int, ...], ...], values: tuple[int, ...]
             ) -> dict[tuple[int, int], list[int]]:
    counts = _degrees(formula)
    buckets: dict[tuple[int, int], list[int]] = {}
    for v in range(n):
        if values[v]:
            continue
        for literal in (v + 1, -(v + 1)):
            key = (min(10, counts[literal]), min(10, counts[-literal]))
            buckets.setdefault(key, []).append(literal)
    for members in buckets.values():
        members.sort(key=lambda lit: (abs(lit), lit < 0))
    return buckets


def _flow(formula: tuple[tuple[int, ...], ...]
          ) -> tuple[int, int, int]:
    occurrences = [lit for clause in formula if len(clause) == 2 for lit in clause]
    if not occurrences:
        return 0, 0, 1
    # These sums are the degree totals for complementary literals over a
    # uniformly selected literal occurrence of a 2-clause.
    f2_counts: Counter[int] = Counter(lit for clause in formula if len(clause) == 2 for lit in clause)
    f3_counts: Counter[int] = Counter(lit for clause in formula if len(clause) == 3 for lit in clause)
    f2 = sum(f2_counts[-lit] for lit in occurrences)
    f3 = sum(f3_counts[-lit] for lit in occurrences)
    return f2, f3, len(occurrences)


def _one_round(n: int, formula: tuple[tuple[int, ...], ...], values: tuple[int, ...], lit: int
               ) -> tuple[tuple[tuple[int, ...], ...], tuple[int, ...]] | None:
    reduced = _simplify(formula, values, lit)
    if reduced is None:
        return None
    forced_formula, forced_values = _force(reduced[0], reduced[1], [])
    return None if forced_formula is None else (forced_formula, forced_values)


def _select(n: int, formula: tuple[tuple[int, ...], ...], values: tuple[int, ...]
            ) -> tuple[int, int] | None:
    old2, old3, old_den = _flow(formula)
    buckets = _members(n, formula, values)
    best_score: tuple[int, int] | None = None
    best_key: tuple[int, int] | None = None
    for key in sorted(buckets):
        outcome = _one_round(n, formula, values, buckets[key][0])
        if outcome is None:
            continue
        f2, f3, den = _flow(outcome[0])
        numerator = f2 * old_den - old2 * den
        denominator = f3 * old_den - old3 * den
        if denominator == 0:
            continue
        if denominator < 0:
            numerator, denominator = -numerator, -denominator
        if (best_score is None or numerator * best_score[1] > best_score[0] * denominator
                or (numerator * best_score[1] == best_score[0] * denominator and key < best_key)):
            best_score, best_key = (numerator, denominator), key
    return best_key


def _run(n: int, formula: tuple[tuple[int, ...], ...]
         ) -> tuple[int, tuple[int, ...], list[tuple[int, int, int, int]]]:
    values = (0,) * n
    trace: list[tuple[int, int, int, int]] = []
    formula, values = _force(formula, values, trace)
    if formula is None:
        return 1, values, trace
    while 0 in values:
        key = _select(n, formula, values)
        if key is None:
            return 2, values, trace
        literal = _members(n, formula, values)[key][0]
        trace.append((literal, 0, key[0], key[1]))
        index = abs(literal) - 1
        sign = 1 if literal > 0 else -1
        attempted_values = values[:index] + (sign,) + values[index + 1:]
        reduced = _simplify(formula, values, literal)
        if reduced is None:
            return 1, attempted_values, trace
        formula, values = _force(reduced[0], reduced[1], trace)
        if formula is None:
            return 1, values, trace
    return 0, values, trace


def expected_output(values: Sequence[int] | None, capacity: int | None = None,
                    output_is_null: bool = False, input_is_null: bool = False,
                    input_length: int | None = None) -> tuple[int, bytes]:
    if (type(output_is_null) is not bool or type(input_is_null) is not bool
            or capacity is not None and (type(capacity) is not int or capacity < 0)
            or input_length is not None and (type(input_length) is not int
                                             or not 0 <= input_length <= MAX_PARSEABLE_INPUT_LENGTH)
            or input_is_null and values not in (None, [], ())
            or not input_is_null and values is not None
            and not isinstance(values, (list, tuple))
            or not input_is_null and values is not None and input_length is not None
            and input_length != len(values)):
        return -1, b""
    if input_is_null or values is None:
        return -1, b""
    decoded = _parse(values)
    if decoded is None:
        return -1, b""
    status, assignment, trace = _run(*decoded)
    words = [status, len(assignment), sum(x != 0 for x in assignment), *assignment, len(trace)]
    for event in trace:
        words.extend(event)
    payload = struct.pack("<" + "q" * len(words), *words)
    if output_is_null or capacity is not None and capacity < len(payload):
        return -2, b""
    return len(payload), payload


def expected_result(values: Sequence[int] | None) -> int:
    return expected_output(values)[0]
