from collections.abc import Sequence
MAX_INPUT_LENGTH=4
INVALID_RESULT=-1
def expected_result(values:Sequence[int])->int:
    if not isinstance(values,(list,tuple)) or len(values)!=4 or any(type(x) is not int or not -(1<<63)<=x<(1<<63) for x in values):return -1
    op,x,y,z=values
    if not 0<=op<=3 or any(abs(v)>1000 for v in (x,y,z)):return -1
    if op==0:return 2*x+2*y*z
    if op==1:return 2*x*z+y*z*z
    if op==2:return 2*x*x+4*y*z
    return (x+y)*z
