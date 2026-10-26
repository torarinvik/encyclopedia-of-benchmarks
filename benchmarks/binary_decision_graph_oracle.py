"""Primary bottom-up unique-table oracle for reduced ordered BDDs."""

MAX_INPUT_LENGTH=65
MAX_NODES=63
MAX_OUTPUT_BYTES=1528


def evaluate(values):
    if values is None or len(values)<2 or len(values)>MAX_INPUT_LENGTH:return -1,b""
    n=values[0]
    if not 1<=n<=6 or len(values)!=1+(1<<n):return -1,b""
    truth=values[1:]
    if any(v not in (0,1) for v in truth):return -1,b""
    ids=list(truth);nodes=[]
    for var in range(n-1,-1,-1):
        current=[];unique={}
        for p in range(1<<var):
            low,high=ids[2*p],ids[2*p+1]
            if low==high:current.append(low);continue
            key=(var,low,high)
            if key not in unique:
                unique[key]=2+len(nodes);nodes.append(key)
            current.append(unique[key])
        ids=current
    root=ids[0];result=[root,len(nodes)]
    for node in nodes:result.extend(node)
    raw=b"".join(int(x).to_bytes(8,"little",signed=True) for x in result)
    return len(raw),raw
