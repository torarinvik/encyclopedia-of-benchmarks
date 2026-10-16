from collections.abc import Sequence
MAX_INPUT_LENGTH=13
INVALID_RESULT=-1
OFFSET=100_000_001
RADIX=200_000_003
def _round(num:int,den:int)->int:
    q=(abs(num)*100_000+den//2)//den
    return q if num>=0 else -q
def expected_result(values:Sequence[int])->int:
    if not isinstance(values,(list,tuple)) or len(values)<5 or len(values)>MAX_INPUT_LENGTH or any(type(x) is not int or not -(1<<63)<=x<(1<<63) for x in values):return -1
    n=values[0]
    if not 2<=n<=6 or len(values)!=1+2*n:return -1
    pts=[values[i:i+2] for i in range(1,len(values),2)]
    if any(abs(x)>20 or abs(y)>20 for x,y in pts):return -1
    sx=sum(x for x,y in pts);sy=sum(y for x,y in pts);sxx=sum(x*x for x,y in pts);sxy=sum(x*y for x,y in pts)
    den=n*sxx-sx*sx
    if den<=0:return -1
    num=n*sxy-sx*sy
    slope=_round(num,den)
    intercept=_round(sy*den-num*sx,n*den)
    if abs(slope)>=OFFSET or abs(intercept)>=OFFSET:return -1
    return (slope+OFFSET)*RADIX+(intercept+OFFSET)
