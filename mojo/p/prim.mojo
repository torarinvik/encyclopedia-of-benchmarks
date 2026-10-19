from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer
@export("prim")
fn prim(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t) abi("C")->Int64:
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or n<2 or n>12290:return -2
    let vertices=v[0];let edges=v[1]
    if vertices<0 or vertices>64 or edges<0 or edges>4096 or n!=c_size_t(2+3*edges):return -2
    let count=Int(vertices);var w=InlineArray[Int64,4096](fill=2147483648)
    for e in range(Int(edges)):
        let u=v[2+3*e];let z=v[3+3*e];let cost=v[4+3*e]
        if u<0 or u>=vertices or z<0 or z>=vertices or cost<0 or cost>2147483647:return -2
        if u==z:continue
        let ix=Int(u)*64+Int(z);let iy=Int(z)*64+Int(u)
        if cost<w[ix]:w[ix]=cost;w[iy]=cost
    if count<=1:return 0
    var used=InlineArray[Bool,64](fill=False);var best=InlineArray[Int64,64](fill=2147483648);best[0]=0
    var total=Int64(0)
    for _ in range(count):
        var node= -1;var distance=Int64(2147483648)
        for i in range(count):if not used[i] and best[i]<distance:distance=best[i];node=i
        if node<0:return -1
        used[node]=True;total+=distance
        for j in range(count):
            let cost=w[node*64+j]
            if not used[j] and cost<best[j]:best[j]=cost
    return total
