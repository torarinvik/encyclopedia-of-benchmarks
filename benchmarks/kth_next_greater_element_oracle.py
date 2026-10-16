from collections.abc import Sequence
MAX_INPUT_LENGTH=8
INVALID_RESULT=-1
def expected_result(values:Sequence[int])->int:
    if not isinstance(values,(list,tuple)) or not 2<=len(values)<=8 or any(type(x) is not int or not -(1<<63)<=x<(1<<63) for x in values):return -1
    k=values[0];a=values[1:]
    if not 1<=k<=7 or any(not -15<=x<=15 for x in a):return -1
    count=0
    for i,x in enumerate(a):
        cur=x;pos=i+1
        for _ in range(k):
            while pos<len(a) and a[pos]<=cur:pos+=1
            if pos==len(a):break
            cur=a[pos];pos+=1
        else:count+=1
    return count
