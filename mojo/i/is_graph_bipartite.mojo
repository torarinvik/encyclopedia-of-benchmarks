from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer
from std.collections import InlineArray

@export("is_graph_bipartite")
fn is_graph_bipartite(input:UnsafePointer[Int64,ImmutAnyOrigin],length:c_size_t) abi("C")->Int64:
    if input==UnsafePointer[Int64,ImmutAnyOrigin]() or length<2 or length>514:return -1
    let nv=input[0];let ne=input[1]
    if nv<0 or nv>64 or ne<0 or ne>256 or length!=c_size_t(2+2*ne):return -1
    var head=InlineArray[Int32,64](fill=-1);var to=InlineArray[Int32,512](fill=0);var next=InlineArray[Int32,512](fill=-1)
    var side=InlineArray[Int32,64](fill=-1);var queue=InlineArray[Int32,64](fill=0);var arcs=0
    for e in range(Int(ne)):
        let ur=input[2+2*e];let vr=input[3+2*e]
        if ur<1 or ur>nv or vr<1 or vr>nv:return -1
        let u=Int(ur)-1;let v=Int(vr)-1
        to[arcs]=Int32(v);next[arcs]=head[u];head[u]=Int32(arcs);arcs+=1
        to[arcs]=Int32(u);next[arcs]=head[v];head[v]=Int32(arcs);arcs+=1
    var ok=True
    for start in range(Int(nv)):
        if side[start]!= -1:continue
        var qh=0;var qt=1;queue[0]=Int32(start);side[start]=0
        while qh<qt:
            let current=Int(queue[qh]);qh+=1;var arc=Int(head[current])
            while arc>=0:
                let neighbor=Int(to[arc])
                if side[neighbor]== -1:side[neighbor]=side[current]^1;queue[qt]=Int32(neighbor);qt+=1
                elif side[neighbor]==side[current]:ok=False
                arc=Int(next[arc])
    return 1 if ok else 0
