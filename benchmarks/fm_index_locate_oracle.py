"""Bounded FM-index locate with LF walks to sampled suffix-array values."""
from __future__ import annotations
import struct
from collections.abc import Sequence
MAX_TEXT=32; MAX_PATTERN=8; MAX_INPUT_LENGTH=43; MAX_PARSEABLE_INPUT_LENGTH=43
MAX_OUTPUT_BYTES=8*(MAX_TEXT+1); ALPHABET=5

def _sa_less(text: list[int], a: int, b: int) -> bool:
    return text[a:] < text[b:]

def _encode(values: Sequence[int]) -> bytes:
    return b"".join(struct.pack("<q", int(x)) for x in values)

def expected_output(values: Sequence[int] | None, capacity: int | None=None, output_is_null: bool=False, input_is_null: bool=False, input_length: int | None=None) -> tuple[int,bytes]:
    if (type(output_is_null) is not bool or type(input_is_null) is not bool or capacity is not None and (type(capacity) is not int or capacity<0) or input_length is not None and (type(input_length) is not int or not 0<=input_length<=MAX_PARSEABLE_INPUT_LENGTH) or input_is_null and values not in (None,[],()) or not input_is_null and values is not None and input_length is not None and input_length!=len(values)):
        return -1,b""
    if input_is_null or not isinstance(values,(list,tuple)) or len(values)<5 or len(values)>MAX_PARSEABLE_INPUT_LENGTH or any(type(x) is not int or not -(1<<63)<=x<(1<<63) for x in values): return -1,b""
    n=values[0]
    if not 1<=n<=MAX_TEXT: return -1,b""
    m_at=n+1; m=values[m_at]
    if not 1<=m<=MAX_PATTERN or len(values)!=m_at+m+2: return -1,b""
    text=list(values[1:1+n]); pattern=list(values[m_at+1:m_at+1+m]); stride=values[-1]
    if any(not 1<=x<=4 for x in text+pattern) or not 1<=stride<=n: return -1,b""
    s=text+[0]; N=n+1; sa=sorted(range(N),key=lambda i:s[i:])
    bwt=[s[(pos-1)%N] for pos in sa]; freq=[0]*ALPHABET
    for c in bwt: freq[c]+=1
    C=[0]*ALPHABET; total=0
    for c in range(ALPHABET): C[c]=total; total+=freq[c]
    left,right=0,N
    for symbol in reversed(pattern):
        rleft=sum(1 for c in bwt[:left] if c==symbol); rright=sum(1 for c in bwt[:right] if c==symbol)
        left=C[symbol]+rleft; right=C[symbol]+rright
        if left==right: break
    sampled=[pos%stride==0 for pos in sa]
    sample_values=sa
    lf=[0]*N
    seen=[0]*ALPHABET
    for row,c in enumerate(bwt): lf[row]=C[c]+seen[c]; seen[c]+=1
    locations=[]
    for start in range(left,right):
        row=start; steps=0
        while not sampled[row]: row=lf[row]; steps+=1
        locations.append((sample_values[row]+steps)%N)
    if any(pos>=n for pos in locations): return -1,b""
    out=_encode((len(locations),*locations))
    if output_is_null or capacity is not None and capacity<len(out): return -2,b""
    return len(out),out
