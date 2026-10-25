"""Independent arbitrary-precision model of 64-bit Montgomery reduction."""
from collections.abc import Sequence
MAX_INPUT_LENGTH=3
MAX_MODULUS=(1<<63)-1
INVALID_RESULT=-1

def expected_result(values):
    if not isinstance(values,Sequence) or len(values)!=3:return INVALID_RESULT
    if any(not isinstance(v,int) for v in values):return INVALID_RESULT
    a,b,m=values
    if m<3 or m>MAX_MODULUS or m%2==0 or a<0 or b<0 or a>=m or b>=m:return INVALID_RESULT
    r_inverse=pow(2,-64,m)
    return (a*b*r_inverse)%m
