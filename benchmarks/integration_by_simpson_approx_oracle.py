"""Reference for the bounded Python Simpson approximation benchmark."""
from __future__ import annotations
import math

INVALID_RESULT=-1.0e300
MAX_INPUT_LENGTH=3

def expected_result(values:list[int])->float:
    if not isinstance(values,list) or len(values)!=3 or any(type(x) is not int or not -(2**63)<=x<2**63 for x in values):return INVALID_RESULT
    a,b,precision=values
    if not -10<=a<=10 or not -10<=b<=10 or a>=b or not 0<=precision<=4:return INVALID_RESULT
    h=(b-a)/1000.0
    result=float(a*a)+float(b*b)
    for i in range(1,1000):
        x=a+h*i
        result+=x*x*(4 if i%2 else 2)
    result*=h/3.0
    return round(result,precision) if math.isfinite(result) else INVALID_RESULT
