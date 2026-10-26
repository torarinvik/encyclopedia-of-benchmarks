"""Primary exhaustive oracle for bounded closest-substring center."""

MAX_INPUT_LENGTH=44
MAX_OUTPUT_BYTES=72


def evaluate(values):
    if values is None or len(values)<4 or len(values)>MAX_INPUT_LENGTH:return -1,b""
    n,m,length,q=values[:4]
    if not 1<=n<=4 or not 1<=m<=10 or not 1<=length<=min(8,m) or q not in (2,3) or len(values)!=4+n*m:return -1,b""
    raw=values[4:]
    if any(x<0 or x>=q for x in raw):return -1,b""
    strings=[raw[i*m:(i+1)*m] for i in range(n)]
    total=q**length;best=length+1;center=None
    for code in range(total):
        v=code;candidate=[0]*length
        for p in range(length-1,-1,-1):candidate[p]=v%q;v//=q
        radius=0
        for s in strings:
            d=min(sum(a!=b for a,b in zip(candidate,s[start:start+length])) for start in range(m-length+1))
            radius=max(radius,d)
        if radius<best:best=radius;center=candidate
    result=[best,*center]
    return 8*len(result),b"".join(int(x).to_bytes(8,"little",signed=True) for x in result)
