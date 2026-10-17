"""Oracle for the bounded Java char-array left-rotation contract."""
from __future__ import annotations
from collections.abc import Sequence
MAX_ARRAY_LENGTH=256
MAX_INPUT_LENGTH=MAX_ARRAY_LENGTH+2
MAX_PARSEABLE_INPUT_LENGTH=MAX_INPUT_LENGTH+1
INVALID_RESULT=-1
INSUFFICIENT_OUTPUT_CAPACITY=-2
I64_MIN=-(1<<63)
I64_MAX=(1<<63)-1
def expected_output(values:Sequence[int]|None,capacity:int|None=None,output_is_null:bool=False,input_is_null:bool=False,input_length:int|None=None)->tuple[int,bytes]:
    if type(input_is_null)is not bool or type(output_is_null)is not bool:return INVALID_RESULT,b""
    if input_is_null and output_is_null:return INVALID_RESULT,b""
    if input_length is not None and (type(input_length)is not int or input_length<0):return INVALID_RESULT,b""
    if input_is_null:
        if not isinstance(values,(list,tuple)) or values or type(input_length)is not int or not 1<=input_length<=MAX_PARSEABLE_INPUT_LENGTH:return INVALID_RESULT,b""
        return INVALID_RESULT,b""
    if values is None or not isinstance(values,(list,tuple)) or len(values)>MAX_PARSEABLE_INPUT_LENGTH:return INVALID_RESULT,b""
    if any(type(x)is not int or not I64_MIN<=x<=I64_MAX for x in values):return INVALID_RESULT,b""
    if input_length is not None and input_length!=len(values):return INVALID_RESULT,b""
    if not 2<=len(values)<=MAX_PARSEABLE_INPUT_LENGTH:return INVALID_RESULT,b""
    n,rotation=values[0],values[1]
    if not 0<=n<=MAX_ARRAY_LENGTH or not 0<=rotation<=n or len(values)!=n+2:return INVALID_RESULT,b""
    if any(not 0<=x<=127 for x in values[2:]):return INVALID_RESULT,b""
    result=bytes(values[2+rotation:])+bytes(values[2:2+rotation])
    if capacity is not None and (type(capacity)is not int or capacity<0):return INVALID_RESULT,b""
    if output_is_null or (capacity is not None and capacity<len(result)):return INSUFFICIENT_OUTPUT_CAPACITY,b""
    return len(result),result
