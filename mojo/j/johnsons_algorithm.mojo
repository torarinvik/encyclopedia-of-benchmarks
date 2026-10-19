from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin,UnsafePointer
from std.collections import InlineArray
fn ja_hash(h0:UInt64,x0:Int64)->UInt64:
    var h=h0;let x=bitcast[UInt64](x0)
    for b in range(8):h=(h^((x>>UInt64(8*b))&255))*UInt64(1099511628211)
    return h
@export("johnsons_algorithm")
fn johnsons_algorithm(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t) abi("C")->Int64:
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or n<1 or n>257 or v[0]<1 or v[0]>16:return -1
    let count=Int(v[0]);if n!=c_size_t(1+count*count):return -1
    var w=InlineArray[Int64,256](fill=0);var edge=InlineArray[Bool,256](fill=False);var reach=InlineArray[Bool,256](fill=False)
    for i in range(count):
        reach[i*16+i]=True
        for j in range(count):
            let x=v[1+i*count+j];if x< -32 or x>32:return -1
            if i!=j and x!=0:edge[i*16+j]=True;w[i*16+j]=x;reach[i*16+j]=True
    for k in range(count):
        for i in range(count):
            for j in range(count):if reach[i*16+j] or (reach[i*16+k] and reach[k*16+j]):reach[i*16+j]=True
    for i in range(count):
        for j in range(count):if not reach[i*16+j]:return -1
    var h=InlineArray[Int64,16](fill=0)
    for it in range(1,count):
        var changed=False
        for i in range(count):
            for j in range(count):
                if edge[i*16+j]:
                    let cand=h[i]+w[i*16+j]
                    if cand<h[j]:h[j]=cand;changed=True
        if not changed:break
    for i in range(count):
        for j in range(count):
            if edge[i*16+j] and (h[i]+w[i*16+j]<h[j] or w[i*16+j]+h[i]-h[j]<=0):return -1
    var hash=UInt64(14695981039346656037);let inf=Int64(9223372036854775807)
    for source in range(count):
        var dist=InlineArray[Int64,16](fill=0);var visited=InlineArray[Bool,16](fill=False)
        for i in range(count):dist[i]=inf
        dist[source]=0
        for step in range(count):
            var cur=count
            for i in range(count):if not visited[i] and (cur==count or dist[i]<=dist[cur]):cur=i
            if cur==count or dist[cur]==inf:break
            visited[cur]=True
            for j in range(count):
                if edge[cur*16+j] and not visited[j]:
                    let cand=dist[cur]+w[cur*16+j]+h[cur]-h[j]
                    if cand<dist[j]:dist[j]=cand
        for dest in range(count):
            let ans=if dist[dest]==inf then Int64(4611686018427387904) else dist[dest]-h[source]+h[dest]
            hash=ja_hash(hash,ans)
    return Int64(hash&UInt64(9223372036854775807))
