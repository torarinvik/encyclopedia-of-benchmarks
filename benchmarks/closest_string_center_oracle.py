"""Primary exhaustive oracle for bounded exact closest-string center."""

MAX_INPUT_LENGTH = 51
MAX_OUTPUT_BYTES = 72


def evaluate(values):
    if values is None or len(values) < 3 or len(values) > MAX_INPUT_LENGTH:
        return -1, b""
    n,m,q=values[:3]
    if not 1<=n<=6 or not 1<=m<=8 or q not in (2,3) or len(values)!=3+n*m:
        return -1,b""
    seq=values[3:]
    if any(x<0 or x>=q for x in seq):return -1,b""
    strings=[seq[i*m:(i+1)*m] for i in range(n)]
    best=m+1;center=None
    count=q**m
    for code in range(count):
        digits=[0]*m;v=code
        for pos in range(m-1,-1,-1):digits[pos]=v%q;v//=q
        radius=max(sum(a!=b for a,b in zip(digits,s)) for s in strings)
        if radius<best:best=radius;center=digits
    result=[best,*center]
    return 8*len(result),b"".join(int(x).to_bytes(8,"little",signed=True) for x in result)
