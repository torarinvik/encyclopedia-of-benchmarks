# Clean-room bounded SAGA-Bench incremental analytics profile; see package LICENSE.txt.
from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

fn saga_push(v: Int, mut queue: InlineArray[Int,8], count: Int, mut seen: InlineArray[Bool,8]) -> Int:
    if seen[v]: return count
    seen[v]=True
    queue[count]=v
    return count+1

@export("saga_incremental_analytics")
fn saga_incremental_analytics(input: UnsafePointer[Int64,ImmutAnyOrigin], length: c_size_t,
                               output: UnsafePointer[UInt8,MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input==UnsafePointer[Int64,ImmutAnyOrigin]() or length<5 or length>97: return -1
    let mode64=input[0]; let n64=input[1]; let base64=input[2]; let added64=input[3]; let source=input[4]
    if mode64<1 or mode64>6 or n64<2 or n64>8 or base64<0 or base64>28 or added64<1 or added64>28: return -1
    if base64+added64>28 or length!=c_size_t(5+n64+3*(base64+added64)): return -1
    let mode=Int(mode64); let n=Int(n64); let base_edges=Int(base64); let edge_count=Int(base64+added64)
    if mode==1 or mode==2 or mode==5:
        if source<0 or source>=n64: return -1
    elif source!=-1: return -1
    var prop=InlineArray[Int64,8](fill=0)
    for v in range(n):
        let value=input[5+v]
        if mode==1 or mode==4 or mode==6:
            if value < -1 or value>=n64: return -1
        elif mode==2 or mode==5:
            if value < -1 or value>1000000000: return -1
        else:
            if value < -1 or value>1000000: return -1
        prop[v]=value
    var neighbors=InlineArray[Int,64](fill=0)
    var weights=InlineArray[Int64,64](fill=0)
    var degree=InlineArray[Int,8](fill=0)
    var used=InlineArray[Bool,64](fill=False)
    var affected=InlineArray[Bool,8](fill=False)
    for e in range(edge_count):
        let pos=5+n+3*e
        let u64=input[pos]; let v64=input[pos+1]; let weight=input[pos+2]
        if u64<0 or v64<=u64 or v64>=n64 or weight<1 or weight>9: return -1
        let u=Int(u64); let v=Int(v64)
        if used[u*8+v]: return -1
        used[u*8+v]=True; used[v*8+u]=True
        neighbors[u*8+degree[u]]=v; weights[u*8+degree[u]]=weight; degree[u]+=1
        neighbors[v*8+degree[v]]=u; weights[v*8+degree[v]]=weight; degree[v]+=1
        if e>=base_edges:
            affected[u]=True
            affected[v]=True
    if mode==3:
        for v in range(n):
            if degree[v]==0: return -1
    if output==UnsafePointer[UInt8,MutAnyOrigin]() or capacity<c_size_t(8*n): return -2
    if mode==1 and prop[Int(source)] == -1: prop[Int(source)]=0
    if mode==2 or mode==5:
        for v in range(n):
            if prop[v]==-1:
                if v==Int(source): prop[v]=0 if mode==2 else 1000000000
                else: prop[v]=1000000000 if mode==2 else 0
    if mode==4 or mode==6:
        for v in range(n):
            if prop[v]==-1: prop[v]=Int64(v)
    if mode==3:
        let damping=Float32(0.85)
        let base=(Float32(1)-damping)/Float32(n)
        var rank=InlineArray[Float32,8](fill=0)
        var contribution=InlineArray[Float32,8](fill=0)
        for v in range(n):
            rank[v]=Float32(1)/Float32(n) if prop[v]==-1 else Float32(prop[v])/Float32(1000000)
            contribution[v]=rank[v]/Float32(degree[v])
        var active=InlineArray[Int,8](fill=0)
        var seen=InlineArray[Bool,8](fill=False)
        var count=0
        for v in range(n):
            if affected[v]:
                var incoming=Float32(0)
                for j in range(degree[v]): incoming+=contribution[neighbors[v*8+j]]
                let old=rank[v]
                rank[v]=base+damping*incoming
                if abs(rank[v]-old)>Float32(0.0000001):
                    for j in range(degree[v]): count=saga_push(neighbors[v*8+j],active,count,seen)
        var rounds=0
        while count!=0:
            rounds+=1
            if rounds>256: return -1
            for v in range(n): contribution[v]=rank[v]/Float32(degree[v])
            var next=InlineArray[Int,8](fill=0)
            var next_seen=InlineArray[Bool,8](fill=False)
            var next_count=0
            for a in range(count):
                let v=active[a]
                var incoming=Float32(0)
                for j in range(degree[v]): incoming+=contribution[neighbors[v*8+j]]
                let old=rank[v]
                rank[v]=base+damping*incoming
                if abs(rank[v]-old)>Float32(0.0000001):
                    for j in range(degree[v]): next_count=saga_push(neighbors[v*8+j],next,next_count,next_seen)
            active=next^
            count=next_count
        for v in range(n): prop[v]=Int64(rank[v]*Float32(1000000)+Float32(0.5))
    else:
        var active=InlineArray[Int,8](fill=0)
        var count=0
        for v in range(n):
            if affected[v]:
                active[count]=v
                count+=1
        var first=True
        var rounds=0
        while count!=0:
            rounds+=1
            if rounds>256: return -1
            var next=InlineArray[Int,8](fill=0)
            var seen=InlineArray[Bool,8](fill=False)
            var next_count=0
            for a in range(count):
                let v=active[a]; let old=prop[v]
                if mode==1 and not first:
                    for j in range(degree[v]):
                        let u=neighbors[v*8+j]; let update=prop[v]+1
                        if prop[u] == -1 or update<prop[u]:
                            prop[u]=update
                            next_count=saga_push(u,next,next_count,seen)
                    continue
                var candidate=Int64(0)
                if mode==1 or mode==2: candidate=1000000000
                if mode==4 or mode==6: candidate=old
                for j in range(degree[v]):
                    let u=neighbors[v*8+j]
                    if mode==1:
                        if prop[u]!=-1: candidate=min(candidate,prop[u]+1)
                    elif mode==2: candidate=min(candidate,prop[u]+weights[v*8+j])
                    elif mode==4: candidate=min(candidate,prop[u])
                    elif mode==5: candidate=max(candidate,min(prop[u],weights[v*8+j]))
                    else: candidate=max(candidate,prop[u])
                var changed=False
                if mode==1: changed=candidate!=1000000000 and (old == -1 or candidate<old)
                elif mode==2: changed=candidate<old and candidate!=1000000000
                elif mode==4: changed=candidate<old or (first and old==Int64(v))
                elif mode==5: changed=candidate>old
                else: changed=candidate>old or (first and old==Int64(v))
                if changed:
                    prop[v]=candidate
                    for j in range(degree[v]):
                        let u=neighbors[v*8+j]
                        if mode==1:
                            let update=candidate+1
                            if prop[u] == -1 or update<prop[u]:
                                prop[u]=update
                                next_count=saga_push(u,next,next_count,seen)
                        else: next_count=saga_push(u,next,next_count,seen)
            active=next^
            count=next_count
            first=False
    for v in range(n):
        let bits=bitcast[UInt64](prop[v])
        for byte in range(8): output[8*v+byte]=UInt8((bits >> UInt(8*byte)) & 255)
    return Int64(8*n)
