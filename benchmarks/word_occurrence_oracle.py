"""Oracle for Python str.split() word occurrence counting on bounded ASCII."""
from __future__ import annotations
import struct
MAX_INPUT=1024
MAX_OUTPUT_BYTES=8192
ASCII_WHITESPACE={9,10,11,12,13,28,29,30,31,32}

def expected_result(values: list[int] | tuple[int,...], output_capacity: int=MAX_OUTPUT_BYTES) -> tuple[int,bytes]:
    if (not isinstance(values,(list,tuple)) or len(values)<1 or len(values)>MAX_INPUT+1
            or any(type(value) is not int or not -(1<<63)<=value<(1<<63) for value in values)):
        return -1,b""
    count=values[0]
    if count<0 or count>MAX_INPUT or len(values)!=count+1 or any(not 0<=value<=127 for value in values[1:]):
        return -1,b""
    occurrences: dict[bytes,int]={}
    token=bytearray()
    def flush() -> None:
        if token:
            key=bytes(token)
            occurrences[key]=occurrences.get(key,0)+1
            token.clear()
    for value in values[1:]:
        if value in ASCII_WHITESPACE: flush()
        else: token.append(value)
    flush()
    output=bytearray(struct.pack("<I",len(occurrences)))
    for word,frequency in occurrences.items():
        output.extend(struct.pack("<I",len(word)))
        output.extend(word)
        output.extend(struct.pack("<I",frequency))
    encoded=bytes(output)
    if output_capacity<len(encoded): return -2,b""
    return len(encoded),encoded
