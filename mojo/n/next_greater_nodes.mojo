from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
@export("next_greater_nodes")
fn next_greater_nodes(a:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t,o:UnsafePointer[UInt8,MutAnyOrigin],cap:c_size_t) abi("C")->Int64:
    if a==UnsafePointer[Int64,ImmutAnyOrigin]() or n<1 or n>4096:return -1
    for i in range(Int(n)):
        if a[i]<1 or a[i]>1000000000:return -1
    let bytes=Int(n)*4
    if o==UnsafePointer[UInt8,MutAnyOrigin]() or cap<c_size_t(bytes):return -2
    for i in range(Int(n)):
        var result:Int64=0
        for j in range(i+1,Int(n)):
            if a[j]>a[i]:result=a[j];break
        let bits=bitcast[UInt32](Int32(result))
        for b in range(4):o[4*i+b]=UInt8((bits>>UInt(8*b))&255)
    return Int64(n)
