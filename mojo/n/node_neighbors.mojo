from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
@export("node_neighbors")
fn node_neighbors(a:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t,o:UnsafePointer[UInt8,MutAnyOrigin],cap:c_size_t) abi("C")->Int64:
    if a==UnsafePointer[Int64,ImmutAnyOrigin]() or n<2 or n>130:return -1
    let edges=a[0];let query=a[1]
    if edges<0 or edges>64 or query<0 or query>63 or n!=c_size_t(2+2*edges):return -1
    var seen=InlineArray[Bool,64](fill=False);var ids=InlineArray[Int64,64]();var count=0
    for i in range(Int(edges)):
        let u=a[2+2*i];let v=a[3+2*i]
        if u<0 or u>63 or v<0 or v>63:return -1
        if u==query and not seen[Int(v)]:seen[Int(v)]=True;ids[count]=v;count+=1
        if v==query and not seen[Int(u)]:seen[Int(u)]=True;ids[count]=u;count+=1
    var staged=InlineArray[UInt8,192]();var bytes=0
    for i in range(count):
        if i>0:staged[bytes]=UInt8(44);bytes+=1
        let x=ids[i]
        if x>=10:staged[bytes]=UInt8(48+x/10);bytes+=1
        staged[bytes]=UInt8(48+x%10);bytes+=1
    if o==UnsafePointer[UInt8,MutAnyOrigin]() or cap<c_size_t(bytes):return -2
    for i in range(bytes):o[i]=staged[i]
    return Int64(bytes)
