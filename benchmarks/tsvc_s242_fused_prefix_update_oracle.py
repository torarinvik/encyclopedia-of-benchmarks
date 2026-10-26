"""Independent oracle for TSVC NodeSplitting s242."""
from __future__ import annotations
import math
from collections.abc import Sequence
MAX_N=64
MAX_INPUT_LENGTH=3+4*MAX_N
MAX_OUTPUT_ELEMENTS=MAX_N
INVALID_RESULT=-1
OUTPUT_ERROR=-2
def expected_output(values:Sequence[int|float],capacity:int=MAX_N,output_is_null:bool=False,input_is_null:bool=False,input_length:int|None=None)->tuple[int,tuple[float,...]]:
    if input_is_null or not isinstance(values,(list,tuple)): return INVALID_RESULT,()
    length=len(values) if input_length is None else input_length
    if type(length) is not int or length!=len(values) or not 7<=length<=MAX_INPUT_LENGTH: return INVALID_RESULT,()
    if any(type(v) not in (int,float) or not math.isfinite(float(v)) for v in values): return INVALID_RESULT,()
    rn=float(values[0])
    if rn!=math.trunc(rn) or not 1<=rn<=MAX_N: return INVALID_RESULT,()
    n=int(rn)
    if length!=3+4*n: return INVALID_RESULT,()
    scalars=values[1:3]
    arrays=[values[3+k*n:3+(k+1)*n] for k in range(4)]
    if any(float(v)!=math.trunc(float(v)) or abs(float(v))>1 for v in (*scalars,*(x for a in arrays for x in a))): return INVALID_RESULT,()
    if type(capacity) is not int or capacity<0: return INVALID_RESULT,()
    if output_is_null or capacity<n: return OUTPUT_ERROR,()
    s1,s2=(float(v) for v in scalars)
    a=[float(v) for v in arrays[0]]
    b,c,d=arrays[1:]
    for i in range(1,n):
        value=a[i-1]+s1
        value=value+s2
        value=value+float(b[i])
        value=value+float(c[i])
        value=value+float(d[i])
        a[i]=value
    return n,tuple(a)
