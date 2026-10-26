"""Independent direct-window verifier for 2D pattern matching."""
import struct
from collections.abc import Sequence

MAX_INPUT=132

def expected_output(values:Sequence[int]|None,capacity:int|None=None,output_is_null:bool=False,input_is_null:bool=False,input_length:int|None=None)->tuple[int,bytes]:
    if type(output_is_null) is not bool or type(input_is_null) is not bool:return -1,b""
    if capacity is not None and (type(capacity) is not int or capacity<0):return -1,b""
    if input_length is not None and (type(input_length) is not int or not 0<=input_length<=MAX_INPUT):return -1,b""
    if input_is_null and values not in (None,[],()):return -1,b""
    if not input_is_null and values is not None and input_length is not None and input_length!=len(values):return -1,b""
    if input_is_null or values is None or not isinstance(values,(list,tuple)):return -1,b""
    if len(values)<6 or len(values)>MAX_INPUT or any(type(x) is not int or not -(1<<63)<=x<(1<<63) for x in values):return -1,b""
    rows,cols,ph,pw=values[:4]
    if not 1<=rows<=8 or not 1<=cols<=8 or not 1<=ph<=rows or not 1<=pw<=cols:return -1,b""
    if len(values)!=4+rows*cols+ph*pw:return -1,b""
    if any(not 0<=x<=3 for x in values[4:]):return -1,b""
    base=4;text=[values[base+r*cols:base+(r+1)*cols] for r in range(rows)];base+=rows*cols
    pattern=[values[base+r*pw:base+(r+1)*pw] for r in range(ph)];matches=[]
    for r in range(rows-ph+1):
        for c in range(cols-pw+1):
            equal=True
            for i in range(ph):
                for j in range(pw):
                    if text[r+i][c+j]!=pattern[i][j]:equal=False
            if equal:matches.append((r,c))
    matches.sort(key=lambda pair:(pair[1],pair[0]))
    payload=b"".join(struct.pack("<q",x) for x in [len(matches),*(v for pair in matches for v in pair)])
    if output_is_null or capacity is not None and capacity<len(payload):return -2,b""
    return len(payload),payload
