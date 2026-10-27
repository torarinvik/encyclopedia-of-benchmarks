"""Independent direct-search verifier for FM-index locate results."""
from __future__ import annotations
import struct
from collections.abc import Sequence
MAX_TEXT=32; MAX_PATTERN=8; MAX_INPUT_LENGTH=43; MAX_PARSEABLE_INPUT_LENGTH=43; MAX_OUTPUT_BYTES=264

def expected_output(values: Sequence[int] | None, capacity: int | None=None, output_is_null: bool=False, input_is_null: bool=False, input_length: int | None=None) -> tuple[int,bytes]:
    if (type(output_is_null) is not bool or type(input_is_null) is not bool or capacity is not None and (type(capacity) is not int or capacity<0) or input_length is not None and (type(input_length) is not int or not 0<=input_length<=MAX_INPUT_LENGTH) or input_is_null and values not in (None,[],()) or not input_is_null and values is not None and input_length is not None and input_length!=len(values)): return -1,b""
    if input_is_null or not isinstance(values,(list,tuple)) or len(values)<5 or len(values)>MAX_INPUT_LENGTH or any(type(v) is not int or not -(1<<63)<=v<(1<<63) for v in values): return -1,b""
    n=values[0]
    if not 1<=n<=MAX_TEXT:return -1,b""
    mpos=n+1;m=values[mpos]
    if not 1<=m<=MAX_PATTERN or len(values)!=mpos+m+2:return -1,b""
    text=list(values[1:mpos]);pattern=list(values[mpos+1:mpos+1+m]);stride=values[-1]
    if any(x<1 or x>4 for x in text+pattern) or not 1<=stride<=n:return -1,b""
    # Enumerate matching starts independently, then sort by full suffix order.
    matches=[i for i in range(n) if i+m<=n and text[i:i+m]==pattern]
    positions=sorted(matches,key=lambda i:tuple(text[i:]+[0]))
    out=b"".join(struct.pack("<q",x) for x in (len(positions),*positions))
    if output_is_null or capacity is not None and capacity<len(out):return -2,b""
    return len(out),out
