"""Primary oracle for the path-restricted DC-Tree server profile."""

MAX_INPUT_LENGTH=18
MAX_OUTPUT_BYTES=480


def _parse(a):
    if a is None or len(a)<5 or len(a)>MAX_INPUT_LENGTH:return None
    k,q=a[0],a[1]
    if not isinstance(k,int) or not 2<=k<=4 or not isinstance(q,int) or not 1<=q<=12:return None
    if len(a)!=2+k+q:return None
    coords=a[2:2+k];requests=a[2+k:]
    if any(not isinstance(x,int) or x<0 or x>15 for x in coords+requests):return None
    return k,q,coords,requests


def evaluate(a):
    parsed=_parse(a)
    if parsed is None:return -1,b""
    k,q,coords,requests=parsed
    pos=list(coords);out=[]
    for request in requests:
        active=[i for i in range(k) if not any(pos[j]==pos[i] for j in range(i))]
        first=min(abs(pos[i]-request) for i in active)
        cost=first*len(active)
        for i in active:
            if pos[i]<request:pos[i]+=first
            elif pos[i]>request:pos[i]-=first
        out.append(cost);out.extend(pos)
    raw=b"".join(x.to_bytes(8,"little",signed=True) for x in out)
    return len(raw),raw
