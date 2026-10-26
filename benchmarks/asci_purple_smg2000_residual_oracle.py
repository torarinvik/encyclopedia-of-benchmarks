"""Independent exact-scaled oracle for the bounded SMG residual kernel."""
from __future__ import annotations

import math
from collections.abc import Sequence

MAX_SIDE = 5
MAX_CELLS = MAX_SIDE**3
MAX_INPUT_LENGTH = 3 + 2 * MAX_CELLS
MIN_INPUT_LENGTH = 3 + 2 * 2**3
INVALID_RESULT = -1
OUTPUT_ERROR = -2
MAX_ABS_FIELD = 1000


def expected_output(values: Sequence[float] | None) -> list[float] | None:
    if values is None or not isinstance(values, (list, tuple)):
        return None
    if not MIN_INPUT_LENGTH <= len(values) <= MAX_INPUT_LENGTH:
        return None
    if any(not math.isfinite(v) or v != math.trunc(v) for v in values):
        return None
    nx, ny, nz = (int(v) for v in values[:3])
    if any(n < 2 or n > MAX_SIDE for n in (nx, ny, nz)):
        return None
    cells = nx * ny * nz
    if len(values) != 3 + 2 * cells:
        return None
    fields = values[3:]
    if any(abs(v) > MAX_ABS_FIELD for v in fields):
        return None

    x = [int(v) for v in fields[:cells]]
    b = [int(v) for v in fields[cells:]]
    row: list[float] = []
    stride_i, stride_j = ny * nz, nz
    # The pinned launcher uses (cx, cy, cz)=(0.1, 1.0, 10.0).
    # Work in tenths so these source coefficients are exact integers here.
    for i in range(nx):
        for j in range(ny):
            for k in range(nz):
                q = i * stride_i + j * stride_j + k
                ax_tenths = 222 * x[q]
                if i > 0:
                    ax_tenths -= x[q - stride_i]
                if i + 1 < nx:
                    ax_tenths -= x[q + stride_i]
                if j > 0:
                    ax_tenths -= 10 * x[q - stride_j]
                if j + 1 < ny:
                    ax_tenths -= 10 * x[q + stride_j]
                if k > 0:
                    ax_tenths -= 100 * x[q - 1]
                if k + 1 < nz:
                    ax_tenths -= 100 * x[q + 1]
                row.append((10 * b[q] - ax_tenths) / 10.0)
    return row


def expected_result(values: Sequence[float] | None) -> int:
    output = expected_output(values)
    return INVALID_RESULT if output is None else len(output)
