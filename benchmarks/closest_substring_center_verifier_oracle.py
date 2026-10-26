"""Independent recursive search with monotone per-string window lower bounds."""


def verify(values):
    if values is None or len(values)<4 or len(values)>44:return -1,b""
    n,m,length,q=values[:4]
    if not 1<=n<=4 or not 1<=m<=10 or not 1<=length<=min(8,m) or q not in (2,3) or len(values)!=4+n*m:return -1,b""
    raw=values[4:]
    if any(x<0 or x>=q for x in raw):return -1,b""
    strings=[raw[i*m:(i+1)*m] for i in range(n)]
    best=length+1;best_center=None;prefix=[]
    def visit(pos):
        nonlocal best,best_center
        lower=0
        for s in strings:
            d=min(sum(prefix[j]!=s[start+j] for j in range(pos)) for start in range(m-length+1))
            lower=max(lower,d)
        if lower>best:return
        if pos==length:
            if lower<best or (lower==best and (best_center is None or tuple(prefix)<tuple(best_center))):
                best=lower;best_center=prefix.copy()
            return
        for symbol in range(q):prefix.append(symbol);visit(pos+1);prefix.pop()
    visit(0)
    result=[best,*best_center]
    return 8*len(result),b"".join(int(x).to_bytes(8,"little",signed=True) for x in result)
