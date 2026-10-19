from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
@export("stalin_sort")
fn stalin_sort(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t,o:UnsafePointer[UInt8,MutAnyOrigin],cap:c_size_t) abi("C")->Int64:
    if n>128 or (n>0 and v==UnsafePointer[Int64,ImmutAnyOrigin]()):return -1
    var count=0;var last:Int64=0
    for i in range(Int(n)):
        if v[i]< -2147483648 or v[i]>2147483647:return -1
        if count==0 or v[i]>=last:count+=1;last=v[i]
    let bytes=count*4
    if o==UnsafePointer[UInt8,MutAnyOrigin]() or cap<c_size_t(bytes):return -2
    count=0;last=0
    for i in range(Int(n)):
        if count==0 or v[i]>=last:
            let bits=bitcast[UInt32](Int32(v[i]));for b in range(4):o[count*4+b]=UInt8((bits>>UInt(8*b))&255)
            count+=1;last=v[i]
    return Int64(bytes)
