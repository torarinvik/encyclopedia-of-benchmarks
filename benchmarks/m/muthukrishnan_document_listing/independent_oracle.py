"""Direct interval-scan reference without previous-occurrence or RMQ data."""

from __future__ import annotations

from typing import Sequence

MIN_N = 1
MAX_N = 32
MIN_DOCUMENTS = 1
MAX_DOCUMENTS = 8
MIN_QUERIES = 1
MAX_QUERIES = 16
MAX_PARSEABLE_INPUT_LENGTH = 3 + MAX_N + 2 * MAX_QUERIES + 1
MAX_OUTPUT_BYTES = MAX_QUERIES * (1 + MAX_DOCUMENTS)


def _parse(values, input_length):
    if values is None:
        return None
    try:
        actual = len(values)
    except (TypeError, ValueError, OverflowError):
        return None
    length = actual if input_length is None else input_length
    if isinstance(length, bool) or not isinstance(length, int):
        return None
    if length < 3 or length > MAX_PARSEABLE_INPUT_LENGTH or length != actual:
        return None
    n, documents, queries = values[:3]
    if any(isinstance(x, bool) or not isinstance(x, int) for x in (n, documents, queries)):
        return None
    if not MIN_N <= n <= MAX_N or not MIN_DOCUMENTS <= documents <= MAX_DOCUMENTS:
        return None
    if not MIN_QUERIES <= queries <= MAX_QUERIES or length != 3 + n + 2 * queries:
        return None
    da = list(values[3:3 + n])
    if any(isinstance(x, bool) or not isinstance(x, int) or x < 0 or x >= documents for x in da):
        return None
    intervals = []
    for query in range(queries):
        lo, hi = values[3 + n + 2 * query:5 + n + 2 * query]
        if any(isinstance(x, bool) or not isinstance(x, int) for x in (lo, hi)):
            return None
        if lo < 0 or hi < lo or hi >= n:
            return None
        intervals.append((lo, hi))
    return da, intervals


def build(values: Sequence[int]) -> bytes:
    parsed = _parse(values, None)
    if parsed is None:
        raise ValueError("invalid bounded document-listing input")
    da, intervals = parsed
    out = bytearray()
    for query_left, query_right in intervals:
        reported = []
        seen: set[int] = set()
        for position in range(query_left, query_right + 1):
            document = da[position]
            if document not in seen:
                seen.add(document)
                reported.append(document)
        out.append(len(reported))
        out.extend(reported)
    if len(out) > MAX_OUTPUT_BYTES:
        raise ValueError("output exceeds bounded profile")
    return bytes(out)


def expected_output(values, capacity=None, output_is_null=False,
                    input_is_null=False, input_length=None):
    if input_is_null or values is None:
        return -1, b""
    parsed = _parse(values, input_length)
    if parsed is None:
        return -1, b""
    encoded = build(values)
    if output_is_null:
        return -2, b""
    if capacity is not None and (
        isinstance(capacity, bool) or not isinstance(capacity, int) or capacity < len(encoded)
    ):
        return -2, b""
    return len(encoded), encoded
