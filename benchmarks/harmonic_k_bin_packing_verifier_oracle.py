"""Independent HARM(k) verifier using explicit bin states."""
from __future__ import annotations
import struct
from collections.abc import Sequence

MIN_K, MAX_K, MAX_N = 3, 8, 32
MAX_INPUT_LENGTH = MAX_PARSEABLE_INPUT_LENGTH = 34
CAPACITY = 10_000
MAX_OUTPUT_BYTES = 264


def _encode(xs: Sequence[int]) -> bytes:
    out = bytearray()
    for x in xs:
        out.extend(struct.pack("<q", int(x)))
    return bytes(out)


def expected_output(values: Sequence[int] | None, capacity: int | None = None,
                    output_is_null: bool = False, input_is_null: bool = False,
                    input_length: int | None = None) -> tuple[int, bytes]:
    if (type(output_is_null) is not bool or type(input_is_null) is not bool
            or capacity is not None and (type(capacity) is not int or capacity < 0)
            or input_length is not None and (type(input_length) is not int or not 0 <= input_length <= MAX_INPUT_LENGTH)
            or input_is_null and values not in (None, [], ())
            or not input_is_null and values is not None and input_length is not None and input_length != len(values)):
        return -1, b""
    if input_is_null or not isinstance(values, (list, tuple)):
        return -1, b""
    if len(values) < 3 or len(values) > MAX_INPUT_LENGTH or any(type(x) is not int or not -(1 << 63) <= x < (1 << 63) for x in values):
        return -1, b""
    k, n = values[0], values[1]
    if not MIN_K <= k <= MAX_K or not 1 <= n <= MAX_N or len(values) != n + 2:
        return -1, b""
    sizes = values[2:]
    if any(s < 1 or s > CAPACITY for s in sizes):
        return -1, b""
    # Each bin keeps its class, load, and active flag. Advancing a class
    # permanently closes its former current bin.
    bins: list[dict[str, int | bool]] = []
    active = [-1] * k
    assignments: list[int] = []
    for size in sizes:
        kind = k - 1
        for i in range(1, k):
            if size * (i + 1) > CAPACITY:
                kind = i - 1
                break
        bid = active[kind]
        if bid < 0 or not bool(bins[bid]["active"]) or int(bins[bid]["load"]) + size > CAPACITY:
            if bid >= 0:
                bins[bid]["active"] = False
            bid = len(bins)
            bins.append({"class": kind, "load": 0, "active": True})
            active[kind] = bid
        bins[bid]["load"] = int(bins[bid]["load"]) + size
        assignments.append(bid)
    out = _encode((len(bins), *assignments))
    if output_is_null or capacity is not None and capacity < len(out):
        return -2, b""
    return len(out), out
