"""Oracle for the deterministic predict path of the PHP sigmoid classifier."""
MAX_INPUT_LENGTH=18
MAX_OUTPUT_BYTES=4

def expected_output(v):
    if not isinstance(v,(list,tuple)) or any(type(x) is not int or not -(2**63)<=x<2**63 for x in v):return -1,b""
    if len(v)<5:return -1,b""
    f,s,bias=v[:3]
    if not 1<=f<=3 or not 1<=s<=4 or not -10000<=bias<=10000:return -1,b""
    if len(v)!=3+f+f*s:return -1,b""
    weights=v[3:3+f]; features=v[3+f:]
    if any(not -10000<=x<=10000 for x in weights) or any(not -10<=x<=10 for x in features):return -1,b""
    out=bytearray()
    for sample in range(s):
        z=bias+sum(weights[i]*features[i*s+sample] for i in range(f))
        out.append(1 if z>0 else 0)
    return s,bytes(out)
