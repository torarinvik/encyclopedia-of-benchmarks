"""Independent oracle for the bounded TSVC s113 invariant-anchor addition."""
from __future__ import annotations
import struct
from collections.abc import Sequence
MAX_N=64;MAX_INPUT_LENGTH=1+2*MAX_N;MAX_OUTPUT_BYTES=8*MAX_N
I64_MIN=-(1<<63);I64_MAX=(1<<63)-1
def expected_output(values:Sequence[int]|None,output_capacity:int|None=None,output_is_null:bool=False,input_is_null:bool=False,input_length:int|None=None)->tuple[int,bytes]:
 if (not isinstance(values,(list,tuple)) or type(output_is_null)is not bool or type(input_is_null)is not bool or output_capacity is not None and (type(output_capacity)is not int or output_capacity<0) or input_length is not None and (type(input_length)is not int or input_length<0 or input_length>MAX_INPUT_LENGTH) or any(type(x)is not int or not I64_MIN<=x<=I64_MAX for x in values)):return -1,b""
 if input_is_null or not 3<=len(values)<=MAX_INPUT_LENGTH:return -1,b""
 if input_length is not None and input_length!=len(values):return -1,b""
 n=values[0]
 if not 1<=n<=MAX_N or len(values)!=1+2*n:return -1,b""
 a=list(values[1:1+n]);b=values[1+n:]
 if any(not -2<=x<=2 for x in (*a,*b)):return -1,b""
 if output_is_null or output_capacity is not None and output_capacity<8*n:return -2,b""
 anchor=a[0]
 for i in range(1,n):a[i]=anchor+b[i]
 return n,b"".join(struct.pack("<q",x) for x in a)
