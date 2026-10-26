"""Independent nearest-arrival replay for DC-Tree movement on a path."""

MAX_INPUT_LENGTH=18
MAX_OUTPUT_BYTES=480


def verify(a):
    if a is None or len(a)<5 or len(a)>18:return -1,b""
    k,q=a[0],a[1]
    if not isinstance(k,int) or k<2 or k>4 or not isinstance(q,int) or q<1 or q>12:return -1,b""
    if len(a)!=2+k+q:return -1,b""
    locations=a[2:2+k];stream=a[2+k:]
    if any(not isinstance(x,int) or x<0 or x>15 for x in locations+stream):return -1,b""
    state=list(locations);record=[]
    for target in stream:
        owners={}
        for server,point in enumerate(state):
            owners.setdefault(point,server)
        distances=[abs(point-target) for point,server in owners.items()]
        elapsed=min(distances)
        moved=0
        for point,server in owners.items():
            moved+=elapsed
            if state[server]<target:state[server]+=elapsed
            elif state[server]>target:state[server]-=elapsed
        record.extend([moved,*state])
    raw=b"".join(x.to_bytes(8,"little",signed=True) for x in record)
    return len(raw),raw
