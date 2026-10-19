"""Integer fixed-point oracle for bounded dyadic HINT area refinement."""

from __future__ import annotations

import struct
from typing import Sequence

MAX_PARSEABLE_INPUT_LENGTH = 4
MAX_OUTPUT_BYTES = 40
INVALID_RESULT = -1
OUTPUT_ERROR = -2


def _run(x_bits: int, y_bits: int, requested: int) -> list[int]:
    scx, scy = 1 << x_bits, 1 << y_bits
    dmax = scx * scy - 1
    count = requested + 1
    rect = [dict(xl=0, xr=0, dx=0, fll=0, flh=0, frl=0, frh=0, ahi=0, alo=0)
            for _ in range(count)]
    rect[0].update(xl=0, xr=scx, dx=scx, fll=scy, flh=scy,
                   frl=0, frh=0, ahi=dmax, alo=0)
    errs = [0] * (2 * count)
    ixes = [0] * (2 * count)
    errs[0], ixes[0] = dmax, 0
    iq, it = 0, 0
    upper, lower = dmax, 0
    while it < requested and it <= iq:
        io = ma = ixes[it]
        jo = it + 1
        parent = rect[ma].copy()
        dx = parent["dx"] // 2
        rect[io]["dx"] = rect[jo]["dx"] = dx
        rect[jo]["xr"] = parent["xr"]
        rect[io]["xr"] = rect[io]["xl"] + dx
        rect[jo]["xl"] = rect[io]["xr"]
        rect[jo]["frl"] = parent["frl"]
        rect[jo]["frh"] = parent["frh"]
        numerator = scy * (scx - rect[io]["xr"])
        denominator = scx + rect[io]["xr"]
        floor_value = numerator // denominator
        ceil_value = floor_value + int(denominator * floor_value != numerator)
        rect[io]["frl"] = floor_value
        rect[io]["frh"] = ceil_value
        rect[jo]["fll"] = floor_value
        rect[jo]["flh"] = ceil_value

        left = rect[io]
        tm = (left["fll"] - left["frh"]) * (left["dx"] - 2)
        if tm < 0:
            tm = 0
        errio = ((left["flh"] - left["frh"] + left["fll"] - left["frl"])
                 * (left["dx"] - 1) - tm)
        right = rect[jo]
        tm = (right["fll"] - right["frh"]) * (right["dx"] - 2)
        if tm < 0:
            tm = 0
        errjo = ((right["flh"] - right["frh"] + right["fll"] - right["frl"])
                 * (right["dx"] - 1) - tm)
        inc = 2 if errio < errjo else 1
        jnc = 3 - inc
        errs[iq + inc], ixes[iq + inc] = errio, io
        errs[iq + jnc], ixes[iq + jnc] = errjo, jo
        iq += int(errs[iq + 2] != 0) + 1

        parent_lower = parent["alo"]
        left["alo"] = left["frl"] * left["dx"]
        right["alo"] = right["frl"] * right["dx"]
        lower = lower - parent_lower + left["alo"] + right["alo"]
        parent_upper = parent["ahi"]
        left["ahi"] = left["flh"] * left["dx"]
        right["ahi"] = right["flh"] * right["dx"]
        upper = upper - parent_upper + left["ahi"] + right["ahi"]
        it += 1
    status = 1 if it > iq else 0
    return [status, it, lower, upper, upper - lower]


def expected_output(
    values: Sequence[int] | None,
    output_capacity: int | None = None,
    output_is_null: bool = False,
    input_is_null: bool = False,
    input_length: int | None = None,
) -> tuple[int, bytes]:
    """Return status and `[kernel_status, splits, lower, upper, gap]` bytes."""
    if (type(output_is_null) is not bool or type(input_is_null) is not bool
            or (output_capacity is not None
                and (type(output_capacity) is not int or output_capacity < 0))
            or (input_length is not None
                and (type(input_length) is not int or input_length < 0))):
        return INVALID_RESULT, b""
    if (input_is_null or not isinstance(values, (list, tuple))
            or len(values) > MAX_PARSEABLE_INPUT_LENGTH
            or (input_length is not None and input_length != len(values))
            or len(values) != 3
            or any(type(value) is not int or not -(1 << 63) <= value < (1 << 63)
                   for value in values)):
        return INVALID_RESULT, b""
    x_bits, y_bits, requested = values
    if not (1 <= x_bits <= 8 and 1 <= y_bits <= 8
            and x_bits + y_bits <= 16
            and 0 <= requested <= min(64, (1 << x_bits) - 1)):
        return -1, b""
    if type(output_is_null) is not bool:
        return -1, b""
    if capacity is not None and (type(capacity) is not int or capacity < 0):
        return INVALID_RESULT, b""
    result = struct.pack("<5q", *_run(x_bits, y_bits, requested))
    if output_is_null or (output_capacity is not None and output_capacity < len(result)):
        return OUTPUT_ERROR, b""
    return len(result), result
