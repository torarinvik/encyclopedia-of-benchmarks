"""Independent oracle for Embench EDN's cascaded IIR section kernel."""
from collections.abc import Sequence
MAX_SECTIONS=8

def oracle(values:Sequence[int],capacity:int|None=None)->tuple[int,bytes]:
    if len(values)<2 or any(type(x) is not int for x in values):return -1,b""
    n,x=values[:2]
    if not 1<=n<=MAX_SECTIONS or len(values)!=2+6*n or not -1024<=x<=1023:return -1,b""
    p=2+4*n;coefs=values[2:p];state=list(values[p:])
    if any(not -1024<=c<=1023 for c in coefs+state):return -1,b""
    for section in range(n):
        c=coefs[4*section:4*section+4];s=2*section
        t=x+((c[2]*state[s]+c[3]*state[s+1])>>15)
        x=t+((c[0]*state[s]+c[1]*state[s+1])>>15)
        state[s+1]=state[s];state[s]=t
    out=b"".join(v.to_bytes(8,"little",signed=True) for v in [x,*state])
    if capacity is not None and capacity<len(out):return -2,b""
    return len(out),out
