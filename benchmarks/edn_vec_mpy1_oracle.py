"""Independent oracle for Embench EDN Q15 vector multiply-add."""
from collections.abc import Sequence
MAX_N=64

def oracle(values:Sequence[int],capacity:int|None=None)->tuple[int,bytes]:
    if len(values)<2 or any(type(x) is not int for x in values):return -1,b""
    n=values[0]
    if not 1<=n<=MAX_N or len(values)!=2+2*n:return -1,b""
    y=list(values[1:1+n]);x=values[1+n:2+2*n];scale=values[-1]
    if any(not -1024<=v<=1023 for v in [*y,*x,scale]):return -1,b""
    for i in range(n):y[i]+=((scale*x[i])>>15)
    out=b"".join(v.to_bytes(8,"little",signed=True) for v in y)
    if capacity is not None and capacity<len(out):return -2,b""
    return len(out),out
