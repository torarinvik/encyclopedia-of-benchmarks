from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer
@export("kcenters")
fn kcenters(a:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t) abi("C")->Int64:
    if a==UnsafePointer[Int64,ImmutAnyOrigin]() or n<2 or n>66:return -1
    let pts=a[0];let k=a[1]
    if pts<1 or pts>8 or k<1 or k>pts or n!=c_size_t(2+pts*pts):return -1
    for i in range(Int(pts)):
        for j in range(Int(pts)):
            let d=a[2+i*Int(pts)+j]
            if d<0 or d>1000000 or d!=a[2+j*Int(pts)+i] or (i==j and d!=0):return -1
    var selected=InlineArray[Bool,8]();var dist=InlineArray[Int64,8]();selected[0]=True
    for i in range(Int(pts)):dist[i]=2147483647
    for i in range(1,Int(pts)):dist[i]=min(dist[i],a[2+i*Int(pts)])
    for _ in range(1,Int(k)):
        var far=-1
        for i in range(Int(pts)):
            if not selected[i] and (far<0 or dist[i]>dist[far]):far=i
        if far<0:return -1
        selected[far]=True
        for i in range(Int(pts)):dist[i]=min(dist[i],a[2+far*Int(pts)+i])
    var best:Int64=0
    for i in range(Int(pts)):best=max(best,dist[i])
    return best
