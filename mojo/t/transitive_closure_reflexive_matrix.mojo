from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
@export("transitive_closure_reflexive_matrix")
fn transitive_closure_reflexive_matrix(a:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t,o:UnsafePointer[UInt8,MutAnyOrigin],cap:c_size_t) abi("C")->Int64:
    if a==UnsafePointer[Int64,ImmutAnyOrigin]() or n<2 or n>1986:return -1
    let nv=a[0];let ne=a[1]
    if nv<1 or nv>32 or ne<0 or ne>nv*(nv-1) or n!=c_size_t(2+2*ne):return -1
    let count=Int(nv);var reach=InlineArray[Bool,1024]()
    for i in range(count):reach[i*count+i]=True
    for e in range(Int(ne)):
        let u=a[2+2*e];let v=a[3+2*e]
        if u<0 or u>=nv or v<0 or v>=nv or u==v:return -1
        let ix=Int(u)*count+Int(v)
        if reach[ix]:return -1
        reach[ix]=True
    for k in range(count):
        for i in range(count):
            if reach[i*count+k]:
                for j in range(count):
                    if reach[k*count+j]:reach[i*count+j]=True
    let bytes=count*count*8
    if o==UnsafePointer[UInt8,MutAnyOrigin]() or cap<c_size_t(bytes):return -2
    for i in range(count*count):
        let v=UInt64(1 if reach[i] else 0)
        for b in range(8):o[i*8+b]=UInt8((v>>(8*b))&255)
    return Int64(bytes)
