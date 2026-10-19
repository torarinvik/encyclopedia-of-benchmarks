from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin,MutAnyOrigin,UnsafePointer
fn wr32rsl(o:UnsafePointer[UInt8,MutAnyOrigin],at:Int,x:Int32):
    let b=UInt32(x);for j in range(4):o[at+j]=UInt8((b>>(8*j))&UInt32(255))
@export("reverse_singly_linked_list")
fn reverse_singly_linked_list(v:UnsafePointer[Int32,ImmutAnyOrigin],n:c_size_t,o:UnsafePointer[UInt8,MutAnyOrigin],cap:c_size_t) abi("C")->Int64:
    if n>256 or v==UnsafePointer[Int32,ImmutAnyOrigin]():return -1
    if o==UnsafePointer[UInt8,MutAnyOrigin]() or cap<c_size_t(Int(n)*4):return -2
    for i in range(Int(n)):wr32rsl(o,i*4,v[Int(n)-1-i])
    return Int64(n)*4
