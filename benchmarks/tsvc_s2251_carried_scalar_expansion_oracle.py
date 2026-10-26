"""Independent oracle for TSVC Expansion s2251."""
from __future__ import annotations
import math
from collections.abc import Sequence
MAX_N=64
MAX_INPUT_LENGTH=1+5*MAX_N
MAX_OUTPUT_ELEMENTS=2*MAX_N
INVALID_RESULT=-1
OUTPUT_ERROR=-2
def expected_output(values: Sequence[int|float], capacity: int=MAX_OUTPUT_ELEMENTS,
                    output_is_null: bool=False, input_is_null: bool=False,
                    input_length: int|None=None)->tuple[int,tuple[float,...]]:
    if input_is_null or not isinstance(values,(list,tuple)): return INVALID_RESULT,()
    length=len(values) if input_length is None else input_length
    if type(length) is not int or length!=len(values) or not 6<=length<=MAX_INPUT_LENGTH: return INVALID_RESULT,()
    if any(type(x) not in (int,float) or not math.isfinite(float(x)) for x in values): return INVALID_RESULT,()
    rn=float(values[0])
    if rn!=math.trunc(rn) or not 1<=rn<=MAX_N: return INVALID_RESULT,()
    n=int(rn)
    if length!=1+5*n: return INVALID_RESULT,()
    arrays=[values[1+k*n:1+(k+1)*n] for k in range(5)]
    if any(float(x)!=math.trunc(float(x)) or abs(float(x))>1 for a in arrays for x in a): return INVALID_RESULT,()
    if type(capacity) is not int or capacity<0: return INVALID_RESULT,()
    if output_is_null or capacity<2*n: return OUTPUT_ERROR,()
    _,b,c,d,e=arrays
    ao=[];bo=[];s=0.0
    for i in range(n):
        av=s*float(e[i])
        s=float(b[i])+float(c[i])
        bv=av+float(d[i])
        ao.append(av);bo.append(bv)
    return 2*n,tuple(ao+bo)
