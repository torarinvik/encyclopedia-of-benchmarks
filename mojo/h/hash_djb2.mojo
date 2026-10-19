from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer
@export("hash_djb2")
fn hash_djb2(a:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t) abi("C")->Int64:
    if a==UnsafePointer[Int64,ImmutAnyOrigin]() or n<1 or n>4:return -1
    let count=a[0]
    if count<0 or count>3 or n!=c_size_t(count+1):return -1
    var h:Int64=5381
    for i in range(Int(count)):
        let b=a[i+1]
        if b<1 or b>127:return -1
        h=h*33+b
    return h
