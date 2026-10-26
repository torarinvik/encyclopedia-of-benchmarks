"""Source-order LPT oracle for the bounded max-min load profile."""
import struct
from collections.abc import Sequence

MAX_N=16
MAX_INPUT=18

def expected_output(values: Sequence[int] | None, capacity: int | None=None,
                    output_is_null: bool=False, input_is_null: bool=False,
                    input_length: int | None=None) -> tuple[int,bytes]:
    if type(output_is_null) is not bool or type(input_is_null) is not bool: return -1,b""
    if capacity is not None and (type(capacity) is not int or capacity<0): return -1,b""
    if input_length is not None and (type(input_length) is not int or not 0<=input_length<=MAX_INPUT): return -1,b""
    if input_is_null and values not in (None,[],()): return -1,b""
    if not input_is_null and values is not None and input_length is not None and input_length!=len(values): return -1,b""
    if input_is_null or values is None or not isinstance(values,(list,tuple)): return -1,b""
    if len(values)<3 or len(values)>MAX_INPUT or any(type(x) is not int or not -(1<<63)<=x<(1<<63) for x in values): return -1,b""
    n,m=values[:2]
    if not 1<=n<=MAX_N or not 1<=m<=4 or len(values)!=2+n or any(not 1<=p<=100 for p in values[2:]): return -1,b""
    order=sorted(range(n),key=lambda i:(-values[2+i],i))
    loads=[0]*m
    assignment=[0]*n
    for job in order:
        machine=min(range(m),key=lambda j:(loads[j],j))
        assignment[job]=machine
        loads[machine]+=values[2+job]
    output=[min(loads),*assignment,*loads]
    payload=b"".join(struct.pack("<q",x) for x in output)
    if output_is_null or capacity is not None and capacity<len(payload): return -2,b""
    return len(payload),payload
