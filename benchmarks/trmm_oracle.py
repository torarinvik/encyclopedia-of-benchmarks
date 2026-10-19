"""Independent bounded oracle for the PolyBench/C TRMM kernel."""
from __future__ import annotations
import math

MIN_DIM = 1
MAX_DIM = 8
MAX_INPUT_LENGTH = 2
MAX_OUTPUT_ELEMENTS = MAX_DIM * MAX_DIM
INVALID_RESULT = -1
OUTPUT_ERROR = -2
ABSOLUTE_TOLERANCE = 1e-12
RELATIVE_TOLERANCE = 1e-12


def _dimensions(values: object) -> tuple[int, int] | None:
    if not isinstance(values, (list, tuple)) or len(values) != 2:
        return None
    dims=[]
    for value in values:
        if not isinstance(value,(int,float)) or isinstance(value,bool): return None
        number=float(value)
        if not math.isfinite(number) or number != math.trunc(number) or not MIN_DIM <= number <= MAX_DIM:
            return None
        dims.append(int(number))
    return dims[0],dims[1]


def expected_output(values: object) -> list[float] | None:
    """Return row-major B after the source initialization and ordered kernel."""
    dims=_dimensions(values)
    if dims is None: return None
    m,n=dims
    alpha=1.5
    a=[[0.0]*m for _ in range(m)]
    b=[[0.0]*n for _ in range(m)]
    for i in range(m):
        for j in range(i): a[i][j]=float((i+j)%m)/float(m)
        a[i][i]=1.0
        for j in range(n): b[i][j]=float((n+i-j)%n)/float(n)
    for i in range(m):
        for j in range(n):
            for k in range(i+1,m): b[i][j]+=a[k][i]*b[k][j]
            b[i][j]=alpha*b[i][j]
    return [b[i][j] for i in range(m) for j in range(n)]


def expected_result(values: object, output_capacity: int, output_is_null: bool=False) -> tuple[int,list[float]]:
    dims=_dimensions(values)
    if dims is None: return INVALID_RESULT,[]
    required=dims[0]*dims[1]
    if output_is_null or output_capacity<required: return OUTPUT_ERROR,[]
    result=expected_output(values)
    assert result is not None
    return len(result),result
