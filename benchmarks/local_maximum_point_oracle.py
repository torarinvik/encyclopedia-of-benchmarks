"""Oracle for the pinned divide-and-conquer local maximum search."""
from collections.abc import Sequence
MAX_INPUT_LENGTH=64
INVALID_RESULT=-1
I64_MIN,I64_MAX=-(1<<63),(1<<63)-1
def expected_result(values:Sequence[int])->int:
    if not isinstance(values,(list,tuple)) or not 1<=len(values)<=MAX_INPUT_LENGTH:return INVALID_RESULT
    if any(type(x) is not int or not I64_MIN<=x<=I64_MAX or not -1000000<=x<=1000000 for x in values):return INVALID_RESULT
    start,end=0,len(values)-1
    while True:
        mid=start+(end-start)//2
        if (mid==0 or values[mid-1]<=values[mid]) and (mid==len(values)-1 or values[mid+1]<=values[mid]):return mid
        if mid>0 and values[mid-1]>values[mid]:end=mid-1
        else:start=mid+1
