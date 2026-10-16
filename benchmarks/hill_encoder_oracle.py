"""Reference behavior for the bounded HillEncoder.Encode contract."""
from __future__ import annotations
import struct

INVALID_RESULT = -1
MAX_INPUT_LENGTH = 74
MAX_OUTPUT_BYTES = 528

def expected_output(values: list[int]) -> tuple[int, bytes]:
    if (not isinstance(values,list) or not 10 <= len(values) <= MAX_INPUT_LENGTH
            or any(type(x) is not int or not -(2**63) <= x < 2**63 for x in values)):
        return INVALID_RESULT,b""
    length=values[0]
    if not 0 <= length <= 64 or len(values) != 10+length:
        return INVALID_RESULT,b""
    text=values[1:1+length]; key=values[1+length:]
    if any(not 65 <= c <= 90 for c in text) or any(not -2 <= k <= 2 for k in key):
        return INVALID_RESULT,b""
    padded=text+[32]*((-length)%3)
    result=[]
    for off in range(0,len(padded),3):
        vector=padded[off:off+3]
        for row in range(3):
            result.append(sum(key[row*3+col]*vector[col] for col in range(3)))
    if any(not 0 <= x <= 0xFFFF for x in result):
        return INVALID_RESULT,b""
    output=struct.pack("<"+"q"*len(result),*result) if result else b""
    return len(output),output
