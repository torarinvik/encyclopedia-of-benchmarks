"""Row-marking plus KMP oracle for a bounded two-dimensional pattern."""
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
    if len(values)!=4+rows*cols+ph*pw or any(not 0<=x<=3 for x in values[4:]):return -1,b""
    cut=4+rows*cols;text=[tuple(values[4+r*cols:4+(r+1)*cols]) for r in range(rows)]
    pattern=[tuple(values[cut+r*pw:cut+(r+1)*pw]) for r in range(ph)]
    marks=[[[False]*ph for _ in range(cols-pw+1)] for _ in range(rows)]
    for r in range(rows):
        for c in range(cols-pw+1):
            for k in range(ph):marks[r][c][k]=text[r][c:c+pw]==pattern[k]
    prefix=[0]*ph
    for i in range(1,ph):
        q=prefix[i-1]
        while q and pattern[i]!=pattern[q]:q=prefix[q-1]
        if pattern[i]==pattern[q]:q+=1
        prefix[i]=q
    matches=[]
    for c in range(cols-pw+1):
        q=0
        for r in range(rows):
            while q and not marks[r][c][q]:q=prefix[q-1]
            if marks[r][c][q]:q+=1
            if q==ph:matches.append((r-ph+1,c));q=prefix[q-1]
    output=[len(matches),*(coordinate for pair in matches for coordinate in pair)]
    payload=b"".join(struct.pack("<q",x) for x in output)
    if output_is_null or capacity is not None and capacity<len(payload):return -2,b""
    return len(payload),payload
