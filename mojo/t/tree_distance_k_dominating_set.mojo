# Uncompiled bounded distance-k tree domination draft.
from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer
@export("tree_distance_k_dominating_set")
fn tree_distance_k_dominating_set(input:UnsafePointer[Int64,ImmutAnyOrigin],length:c_size_t) abi("C")->Int64:
    if input==UnsafePointer[Int64,ImmutAnyOrigin]() or length<2 or length>66: return -1
    let nv=input[0]
    let radius=input[1]
    if nv<1 or nv>64 or radius<0 or radius>63 or length!=c_size_t(nv+1): return -1
    let n=Int(nv)
    var parent=InlineArray[Int,64](fill=0)
    var depth=InlineArray[Int,64](fill=0)
    var first=InlineArray[Int,64](fill=-1)
    var next=InlineArray[Int,64](fill=-1)
    var covered=InlineArray[Bool,64](fill=False)
    for v in range(1,n):
        let raw=input[1+v]
        if raw<0 or raw>=Int64(v): return -1
        let p=Int(raw)
        parent[v]=p; depth[v]=depth[p]+1; next[v]=first[p]; first[p]=v
    var answer:Int64=0
    while True:
        var deepest = -1
        for v in range(n):
            if not covered[v] and (deepest<0 or depth[v]>depth[deepest]): deepest=v
        if deepest<0: return answer
        var center=deepest
        var step:Int64=0
        while step<radius and center!=0:
            center=parent[center]
            step+=1
        var queue=InlineArray[Int,64](fill=0)
        var dist=InlineArray[Int,64](fill=-1)
        var head=0
        var tail=1
        queue[0]=center; dist[center]=0
        while head<tail:
            let v=queue[head]
            head+=1
            covered[v]=True
            if Int64(dist[v])==radius: continue
            if v!=0 and dist[parent[v]]<0:
                let u=parent[v]
                dist[u]=dist[v]+1; queue[tail]=u; tail+=1
            var u=first[v]
            while u>=0:
                if dist[u]<0:
                    dist[u]=dist[v]+1; queue[tail]=u; tail+=1
                u=next[u]
        answer+=1
