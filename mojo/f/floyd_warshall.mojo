from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

comptime FW_MAX=64

@export("floyd_warshall")
fn floyd_warshall(edges:UnsafePointer[Int64,ImmutAnyOrigin],vertices:c_size_t,edge_count:c_size_t,source:c_size_t,
                  distances:UnsafePointer[Int64,MutAnyOrigin],reachable:UnsafePointer[UInt8,MutAnyOrigin]) abi("C")->Int64:
    let n=Int(vertices);let m=Int(edge_count);let src=Int(source)
    if n==0:
        if src==0 and m==0:return 0
        return -3
    if n>FW_MAX or src>=n or (m>0 and edges==UnsafePointer[Int64,ImmutAnyOrigin]()) or distances==UnsafePointer[Int64,MutAnyOrigin]() or reachable==UnsafePointer[UInt8,MutAnyOrigin]():return -3
    var d=InlineArray[Int64,4096](fill=0)
    var present=InlineArray[Bool,4096](fill=False)
    for v in range(n):present[v*n+v]=True
    for e in range(m):
        let a=edges[3*e];let b=edges[3*e+1];let w=edges[3*e+2]
        if a<0 or b<0 or a>=vertices or b>=vertices:return -3
        let idx=Int(a)*n+Int(b)
        if not present[idx] or w<d[idx]:d[idx]=w;present[idx]=True
    for k in range(n):
        for i in range(n):
            let li=i*n+k
            if not present[li]:continue
            for j in range(n):
                let ri=k*n+j
                if not present[ri]:continue
                let left=d[li];let right=d[ri]
                if (right>0 and left>9223372036854775807-right) or (right<0 and left< -9223372036854775807-1-right):return -2
                let candidate=left+right;let oi=i*n+j
                if not present[oi] or candidate<d[oi]:d[oi]=candidate;present[oi]=True
    for v in range(n):
        let idx=src*n+v
        if present[idx] and present[v*n+v] and d[v*n+v]<0:return -1
    for v in range(n):
        let idx=src*n+v
        reachable[v]=UInt8(1 if present[idx] else 0)
        distances[v]=d[idx] if present[idx] else 0
    return 0
