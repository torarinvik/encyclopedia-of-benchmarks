"""Independent state-table verifier for the bounded streaming estimator."""

MAX_INPUT_LENGTH=340
MAX_OUTPUT_BYTES=672
SCALE=1_000_000

def make_wedge(a,b):
    common=set(a).intersection(b)
    if len(common)!=1:return None
    center=next(iter(common))
    return tuple(sorted((a[0] if a[1]==center else a[1],
                         b[0] if b[1]==center else b[1])))


def verify(a):
    if a is None or len(a)<10 or len(a)>340:return -1,b""
    n,m,se,sw=a[:4]
    if any(not isinstance(v,int) for v in (n,m,se,sw)) or n<2 or n>8 or m<1 or m>28 or se<2 or se>4 or sw<1 or sw>4:return -1,b""
    block=2+2*sw
    if len(a)!=4+2*m+m*block:return -1,b""
    stream=[];edge_keys=set()
    for r in range(m):
        x,y=a[4+2*r:6+2*r]
        if not isinstance(x,int) or not isinstance(y,int) or x<0 or y<=x or y>=n or (x,y) in edge_keys:return -1,b""
        edge_keys.add((x,y));stream.append((x,y))
    edge_slots=[None]*se
    sampled=[None]*sw
    flags=[0]*sw
    total=0
    answers=[]
    tape=4+2*m
    for r,arriving in enumerate(stream):
        t=r+1
        for j in range(sw):
            item=sampled[j]
            if item is not None and item[0]==arriving[0] and item[1]==arriving[1]:flags[j]=1
        pos=tape+r*block
        toss,chosen=a[pos],a[pos+1]
        den=t**se
        cutoff=den-(t-1)**se
        if not isinstance(toss,int) or toss<0 or toss>=den:return -1,b""
        if toss<cutoff:
            if not isinstance(chosen,int) or chosen<0 or chosen>=se:return -1,b""
            removed=0
            old_id=edge_slots[chosen]
            if old_id is not None:
                old_edge=stream[old_id]
                for q,edge_id in enumerate(edge_slots):
                    if q!=chosen and edge_id is not None:
                        old=stream[edge_id]
                        if make_wedge(old_edge,old) is not None:removed+=1
            edge_slots[chosen]=r
            candidate=[]
            for q,edge_id in enumerate(edge_slots):
                if q==chosen or edge_id is None:continue
                old=stream[edge_id]
                shared=[z for z in arriving if z in old]
                if len(shared)==1:
                    ends=sorted((arriving[0] if arriving[1]==shared[0] else arriving[1],
                                 old[0] if old[1]==shared[0] else old[1]))
                    candidate.append(tuple(ends))
        else:
            if chosen!=0:return -1,b""
            removed=0
            candidate=[]
        total+=len(candidate)-removed
        if total<0:return -1,b""
        for j in range(sw):
            rand,rank=a[pos+2+2*j],a[pos+3+2*j]
            if candidate:
                if not isinstance(rand,int) or rand<0 or rand>=total:return -1,b""
                if rand<len(candidate):
                    if not isinstance(rank,int) or rank<0 or rank>=len(candidate):return -1,b""
                    sampled[j]=candidate[rank];flags[j]=0
                elif rank!=0:return -1,b""
            elif rand!=0 or rank!=0:return -1,b""
        hits=sum(flags)
        answers += [total,(3*hits*SCALE)//sw,(hits*t*t*total*SCALE)//(sw*se*(se-1))]
    raw=b"".join(v.to_bytes(8,"little",signed=True) for v in answers)
    return len(raw),raw
