"""Independent recursive branch-and-bound verifier for closest-string center."""


def verify(values):
    if values is None or len(values)<3 or len(values)>51:return -1,b""
    n,m,q=values[:3]
    if not 1<=n<=6 or not 1<=m<=8 or q not in (2,3) or len(values)!=3+n*m:return -1,b""
    raw=values[3:]
    if any(x<0 or x>=q for x in raw):return -1,b""
    strings=[raw[i*m:(i+1)*m] for i in range(n)]
    best_radius=m+1;best_center=None;prefix=[]
    def visit(position):
        nonlocal best_radius,best_center
        partial=[sum(prefix[j]!=s[j] for j in range(position)) for s in strings]
        lower=max(partial)
        if lower>best_radius:return
        if position==m:
            if lower<best_radius or (lower==best_radius and (best_center is None or tuple(prefix)<tuple(best_center))):
                best_radius=lower;best_center=prefix.copy()
            return
        for symbol in range(q):
            prefix.append(symbol);visit(position+1);prefix.pop()
    visit(0)
    result=[best_radius,*best_center]
    return 8*len(result),b"".join(int(x).to_bytes(8,"little",signed=True) for x in result)
