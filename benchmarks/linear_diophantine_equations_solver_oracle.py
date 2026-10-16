"""Oracle for the pinned Java extended-Euclidean Diophantine solver."""
from collections.abc import Sequence
MAX_INPUT_LENGTH=3
INVALID_RESULT=-1
OFFSET=10_000_001
RADIX=20_000_003
def _java_div(a:int,b:int)->int:
    return abs(a)//abs(b)*(1 if (a>=0)==(b>=0) else -1)
def _gcd_solution(a:int,b:int):
    if b==0:return a,1,0
    g,x1,y1=_gcd_solution(b,a-_java_div(a,b)*b)
    return g,y1,x1-_java_div(a,b)*y1
def expected_result(values:Sequence[int])->int:
    if not isinstance(values,(list,tuple)) or len(values)!=3 or any(type(v) is not int or not -(1<<63)<=v<(1<<63) for v in values):return INVALID_RESULT
    a,b,c=values
    if any(abs(v)>1000 for v in (a,b)) or abs(c)>10000:return INVALID_RESULT
    if a==0 and b==0:return -3 if c==0 else -2
    if a==0:
        if c%b:return -2
        x,y=0,c//b
    elif b==0:
        if c%a:return -2
        x,y=c//a,0
    else:
        g,xg,yg=_gcd_solution(a,b)
        if c%g:return -2
        x,y=xg*(c//g),yg*(c//g)
    if not (-OFFSET<x<OFFSET and -OFFSET<y<OFFSET):return INVALID_RESULT
    return (x+OFFSET)*RADIX+(y+OFFSET)
