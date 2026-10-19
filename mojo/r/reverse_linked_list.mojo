from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin,MutAnyOrigin,UnsafePointer
fn wr64rl(o:UnsafePointer[UInt8,MutAnyOrigin],at:Int,x:Int64):
    let b=UInt64(x);for j in range(8):o[at+j]=UInt8((b>>(8*j))&UInt64(255))
@export("reverse_linked_list")
fn reverse_linked_list(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t,o:UnsafePointer[UInt8,MutAnyOrigin],cap:c_size_t) abi("C")->Int64:
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or n<2 or n>257 or v[0]<1 or v[0]>256 or Int(n)!=Int(v[0])+1:return -1
    let size=Int(v[0]);if o==UnsafePointer[UInt8,MutAnyOrigin]() or cap<c_size_t(8*size):return -2
    for i in range(size):wr64rl(o,i*8,v[size-i])
    return Int64(size*8)
