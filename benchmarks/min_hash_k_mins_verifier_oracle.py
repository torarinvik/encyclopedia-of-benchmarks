"""Independent scan verifier for k-mins under supplied rank functions."""
import struct
from collections.abc import Sequence

MAX_INPUT=66

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
    n,k=values[0],values[1]
    if not 1<=n<=16 or not 1<=k<=4 or len(values)!=2+n*k: return -1,b""
    for x in values[2:]:
        if not 0<=x<=1000: return -1,b""
    chosen=[]
    for column in range(k):
        best=0
        for row in range(1,n):
            rank=values[2+row*k+column]
            best_rank=values[2+best*k+column]
            if rank<best_rank: best=row
        chosen.append(best)
    payload=b"".join(struct.pack("<q",x) for x in chosen)
    if output_is_null or capacity is not None and capacity<len(payload): return -2,b""
    return len(payload),payload
