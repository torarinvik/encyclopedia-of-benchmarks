"""Full group-closure enumeration oracle, independent of the stabilizer chain."""

from __future__ import annotations

from collections import deque
from collections.abc import Sequence
import struct

try:
    from .primary_oracle import (
        INVALID, OUTPUT_ERROR, _parse,
    )
except ImportError:  # Direct import from this package directory.
    from primary_oracle import (
        INVALID, OUTPUT_ERROR, _parse,
    )


def _identity(n: int) -> tuple[int, ...]:
    return tuple(range(n))


def _inverse(permutation: tuple[int, ...]) -> tuple[int, ...]:
    result = [0] * len(permutation)
    for point, image in enumerate(permutation):
        result[image] = point
    return tuple(result)


def _compose(first: tuple[int, ...], second: tuple[int, ...]) -> tuple[int, ...]:
    return tuple(second[first[i]] for i in range(len(first)))


def _closure(n: int, generators: list[tuple[int, ...]]) -> set[tuple[int, ...]]:
    identity = _identity(n)
    steps = list(generators)
    steps.extend(_inverse(generator) for generator in generators)
    seen = {identity}
    pending = deque([identity])
    while pending:
        current = pending.popleft()
        for step in steps:
            candidate = _compose(current, step)
            if candidate not in seen:
                seen.add(candidate)
                pending.append(candidate)
    return seen


def expected_output(
    values: Sequence[int] | None,
    output_capacity: int | None = None,
    output_is_null: bool = False,
    input_is_null: bool = False,
    input_length: int | None = None,
) -> tuple[int, bytes]:
    if (type(output_is_null) is not bool or type(input_is_null) is not bool
            or output_capacity is not None and (type(output_capacity) is not int or output_capacity < 0)):
        return INVALID, b""
    parsed = _parse(values, input_is_null, input_length)
    if parsed is None:
        return INVALID, b""
    n, generators, queries = parsed
    required = 8 * (1 + len(queries))
    if output_is_null or output_capacity is not None and output_capacity < required:
        return OUTPUT_ERROR, b""
    elements = _closure(n, generators)
    answers = [len(elements)]
    answers.extend(int(query in elements) for query in queries)
    payload = b"".join(struct.pack("<q", answer) for answer in answers)
    return len(payload), payload
