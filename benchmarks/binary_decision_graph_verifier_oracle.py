"""Independent recursive Shannon-cofactor verifier for canonical ROBDD output."""


def verify(values):
    if values is None or len(values)<2 or len(values)>65:return -1,b""
    n=values[0]
    if not 1<=n<=6 or len(values)!=1+(1<<n):return -1,b""
    truth=values[1:]
    if any(v not in (0,1) for v in truth):return -1,b""
    by_level=[[] for _ in range(n)];unique={}
    def build(level,rows):
        if level==n:return rows[0]
        half=len(rows)//2
        low=build(level+1,rows[:half]);high=build(level+1,rows[half:])
        if low==high:return low
        key=(level,low,high)
        if key not in unique:
            unique[key]=key;by_level[level].append(key)
        return unique[key]
    root=build(0,list(truth));ids={0:0,1:1};nodes=[]
    for level in range(n-1,-1,-1):
        for key in by_level[level]:
            _var,low,high=key
            node=(level,ids[low],ids[high]);ids[key]=2+len(nodes);nodes.append(node)
    result=[ids[root],len(nodes)]
    for node in nodes:result.extend(node)
    raw=b"".join(int(x).to_bytes(8,"little",signed=True) for x in result)
    return len(raw),raw
