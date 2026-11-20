"""Direct exhaustive rank-signature optimum, independent of phase reduction."""

from __future__ import annotations

from collections.abc import Sequence
import struct

from .primary_oracle import (
    INVALID_RESULT,
    MAX_APPLICANTS,
    MAX_EDGES,
    MAX_PARSEABLE_INPUT_LENGTH,
    MAX_POSTS,
    MAX_RANK,
    OUTPUT_ERROR_RESULT,
)


def _parse(values: Sequence[int] | None, input_is_null: bool,
           input_length: int | None):
    if (type(input_is_null) is not bool or input_is_null
            or not isinstance(values, (list, tuple))
            or not 3 <= len(values) <= MAX_PARSEABLE_INPUT_LENGTH
            or any(type(value) is not int or not -(1 << 63) <= value < (1 << 63)
                   for value in values)):
        return None
    if input_length is None:
        input_length = len(values)
    if type(input_length) is not int or input_length != len(values):
        return None
    applicants, posts, edge_count = values[:3]
    if not 1 <= applicants <= MAX_APPLICANTS or not 1 <= posts <= MAX_POSTS:
        return None
    if not applicants <= edge_count <= min(MAX_EDGES, applicants * posts):
        return None
    if len(values) != 3 + 3 * edge_count:
        return None
    ranks = [[0] * posts for _ in range(applicants)]
    degree = [0] * applicants
    max_rank = 0
    for offset in range(3, len(values), 3):
        applicant, post, rank = values[offset:offset + 3]
        if (not 0 <= applicant < applicants or not 0 <= post < posts
                or not 1 <= rank <= MAX_RANK or ranks[applicant][post]):
            return None
        ranks[applicant][post] = rank
        degree[applicant] += 1
        max_rank = max(max_rank, rank)
    if any(value == 0 for value in degree):
        return None
    return applicants, posts, max_rank, ranks


def expected_output(values: Sequence[int] | None, capacity: int | None = None,
                    output_is_null: bool = False, input_is_null: bool = False,
                    input_length: int | None = None) -> tuple[int, bytes]:
    parsed = _parse(values, input_is_null, input_length)
    if parsed is None:
        return INVALID_RESULT, b""
    applicants, posts, max_rank, ranks = parsed
    best: tuple[int, ...] | None = None
    base = posts + 1
    for code in range(base ** applicants):
        value = code
        used = 0
        signature = [0] * max_rank
        valid = True
        for applicant in range(applicants):
            post = value % base
            value //= base
            if post == posts:
                continue
            rank = ranks[applicant][post]
            if rank == 0 or used & (1 << post):
                valid = False
                break
            used |= 1 << post
            signature[rank - 1] += 1
        candidate = tuple(signature)
        if valid and (best is None or candidate > best):
            best = candidate
    assert best is not None
    payload = struct.pack("<" + "q" * (max_rank + 1), max_rank, *best)
    if capacity is None:
        capacity = len(payload)
    if (type(output_is_null) is not bool or type(capacity) is not int
            or capacity < 0 or output_is_null or capacity < len(payload)):
        return OUTPUT_ERROR_RESULT, b""
    return len(payload), payload
