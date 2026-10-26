"""Primary explicit-random-tape oracle for Streaming-Triangles."""

MAX_INPUT_LENGTH = 340
MAX_OUTPUT_BYTES = 672
SCALE = 1_000_000


def _parse(a):
    if a is None or len(a) < 10 or len(a) > MAX_INPUT_LENGTH:
        return None
    n, m, se, sw = a[:4]
    if not all(isinstance(x, int) for x in (n,m,se,sw)) or not 2 <= n <= 8 or not 1 <= m <= 28 or not 2 <= se <= 4 or not 1 <= sw <= 4:
        return None
    stride = 2 + 2*sw
    if len(a) != 4 + 2*m + m*stride:
        return None
    edges=[];seen=set()
    for i in range(m):
        u,v=a[4+2*i:6+2*i]
        if not isinstance(u,int) or not isinstance(v,int) or not 0<=u<v<n or (u,v) in seen:
            return None
        seen.add((u,v));edges.append((u,v))
    return n,m,se,sw,edges,4+2*m,stride


def _wedges(edge_id, edge_res, edges, skip):
    u,v=edges[edge_id];found=[]
    for slot,other_id in enumerate(edge_res):
        if slot==skip or other_id<0:continue
        a,b=edges[other_id]
        common=set((u,v)).intersection((a,b))
        if len(common)==1:
            center=next(iter(common))
            x= u if v==center else v
            y= a if b==center else b
            found.append(tuple(sorted((x,y))))
    return found


def evaluate(a):
    parsed=_parse(a)
    if parsed is None:return -1,b""
    n,m,se,sw,edges,base,stride=parsed
    edge_res=[-1]*se
    wedge_res=[None]*sw
    closed=[False]*sw
    total_wedges=0
    staged=[]
    for ti,edge in enumerate(edges):
        t=ti+1
        for j,w in enumerate(wedge_res):
            if w is not None and w==edge:closed[j]=True
        rec=base+ti*stride
        edge_draw=a[rec];edge_slot=a[rec+1]
        limit=t**se
        threshold=limit-(t-1)**se
        if not isinstance(edge_draw,int) or not 0<=edge_draw<limit:return -1,b""
        update=edge_draw<threshold
        if not isinstance(edge_slot,int):return -1,b""
        if update:
            if not 0<=edge_slot<se:return -1,b""
            removed=0
            old_id=edge_res[edge_slot]
            if old_id>=0:
                removed=len(_wedges(old_id,edge_res,edges,edge_slot))
            edge_res[edge_slot]=ti
            fresh=_wedges(ti,edge_res,edges,edge_slot)
        else:
            if edge_slot!=0:return -1,b""
            removed=0
            fresh=[]
        total_wedges+=len(fresh)-removed
        if total_wedges<0:return -1,b""
        for s in range(sw):
            draw=a[rec+2+2*s];pick=a[rec+3+2*s]
            if fresh:
                if not isinstance(draw,int) or not 0<=draw<total_wedges:return -1,b""
                if draw<len(fresh):
                    if not isinstance(pick,int) or not 0<=pick<len(fresh):return -1,b""
                    wedge_res[s]=fresh[pick];closed[s]=False
                elif pick!=0:return -1,b""
            elif draw!=0 or pick!=0:
                return -1,b""
        closed_count=sum(closed)
        kappa_q=(3*closed_count*SCALE)//sw
        triangle_q=(closed_count*t*t*total_wedges*SCALE)//(sw*se*(se-1))
        staged.extend((total_wedges,kappa_q,triangle_q))
    raw=b"".join(int(x).to_bytes(8,"little",signed=True) for x in staged)
    return len(raw),raw
