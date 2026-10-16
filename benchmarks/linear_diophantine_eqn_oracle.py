"""Oracle for bounded linear Diophantine solvability."""
from collections.abc import Sequence
MAX_INPUT_LENGTH=3
INVALID_RESULT=-1
I64_MIN,I64_MAX=-(1<<63),(1<<63)-1
def expected_result(values:Sequence[int])->int:
    if not isinstance(values,(list,tuple)) or len(values)!=3 or any(type(x) is not int or not I64_MIN<=x<=I64_MAX for x in values):return INVALID_RESULT
    a,b,c=values
    if not -100000<=a<=100000 or not -100000<=b<=100000 or b==0 or not -1000000<=c<=1000000:return INVALID_RESULT
    return int(c%math_gcd(a,b)==0)
def math_gcd(a:int,b:int)->int:
    a,b=abs(a),abs(b)
    while b:a,b=b,a%b
    return a
