from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin,MutAnyOrigin,UnsafePointer
@export("reverse_string")
fn reverse_string(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t,o:UnsafePointer[UInt8,MutAnyOrigin],cap:c_size_t) abi("C")->Int64:
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or n<1 or v[0]<0 or v[0]>256 or Int(n)!=Int(v[0])+1:return -1
    let size=Int(v[0]);for i in range(size):if v[i+1]<33 or v[i+1]>126:return -1
    if o==UnsafePointer[UInt8,MutAnyOrigin]() or cap<c_size_t(size+1):return -2
    for i in range(size):o[i]=UInt8(v[size-i])
    o[size]=0;return Int64(size)
