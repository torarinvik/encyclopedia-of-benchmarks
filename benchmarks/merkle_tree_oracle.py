"""Bounded oracle for the pinned Merkle-root construction."""
import hashlib
MIN_LEAF_COUNT = 1
MAX_LEAF_COUNT = 16
MAX_LEAF_BYTES = 64
MAX_ASCII_BYTE = 127
MAX_INPUT_LENGTH = 1 + MAX_LEAF_COUNT * (1 + MAX_LEAF_BYTES)
MAX_OUTPUT_BYTES = 64
I64_MIN = -(1 << 63)
I64_MAX = (1 << 63) - 1


def expected_result(values, output_capacity=MAX_OUTPUT_BYTES):
    if (not isinstance(values, (list, tuple))
            or not 1 <= len(values) <= MAX_INPUT_LENGTH
            or any(type(x) is not int or not I64_MIN <= x <= I64_MAX for x in values)):
        return -1, b""
    count=values[0]
    if not MIN_LEAF_COUNT <= count <= MAX_LEAF_COUNT: return -1,b""
    leaves=[];i=1
    for _ in range(count):
        if i>=len(values): return -1,b""
        n=values[i];i+=1
        if not 0 <= n <= MAX_LEAF_BYTES or i + n > len(values): return -1, b""
        chunk=values[i:i+n]
        if any(not 0 <= x <= MAX_ASCII_BYTE for x in chunk): return -1, b""
        leaves.append(bytes(chunk));i+=n
    if i!=len(values): return -1,b""
    level=[hashlib.sha256(leaf).hexdigest() for leaf in leaves]
    while len(level)>1:
        nxt=[]
        for j in range(0,len(level),2):
            right=level[j+1] if j+1<len(level) else level[j]
            nxt.append(hashlib.sha256((level[j]+right).encode("ascii")).hexdigest())
        level=nxt
    out=level[0].encode("ascii")
    if output_capacity<len(out): return -2,b""
    return len(out),out
