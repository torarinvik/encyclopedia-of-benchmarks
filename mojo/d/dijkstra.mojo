from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin,MutAnyOrigin,UnsafePointer
@export("dijkstra")
fn dijkstra(edges:UnsafePointer[Int64,ImmutAnyOrigin],vertices:c_size_t,edge_count:c_size_t,source:c_size_t,distances:UnsafePointer[Int64,MutAnyOrigin],reachable:UnsafePointer[UInt8,MutAnyOrigin]) abi("C")->Int64:
    let n=Int(vertices);let m=Int(edge_count);let s=Int(source)
    if n==0:return 0 if s==0 and m==0 else -3
    if s>=n:return -3
    if m>0 and edges==UnsafePointer[Int64,ImmutAnyOrigin]():return -3
    for e in range(m):
        let u=edges[3*e];let v=edges[3*e+1];let w=edges[3*e+2]
        if u<0 or u>=Int64(n) or v<0 or v>=Int64(n):return -3
        if w<0:return -4
    for i in range(n):distances[i]=0;reachable[i]=0
    reachable[s]=1
    for round in range(n):
        var selected=n;var best:Int64=0
        for i in range(n):
            if reachable[i]==1 and (selected==n or distances[i]<best):selected=i;best=distances[i]
        if selected==n:break
        reachable[selected]=2
        for e in range(m):
            if Int(edges[3*e])!=selected:continue
            let dest=Int(edges[3*e+1]);let weight=edges[3*e+2];let base=distances[selected]
            if base>9223372036854775807-weight:return -2
            let candidate=base+weight
            if reachable[dest]!=2 and (reachable[dest]==0 or candidate<distances[dest]):distances[dest]=candidate;reachable[dest]=1
    for i in range(n):if reachable[i]==2:reachable[i]=1
    return 0
