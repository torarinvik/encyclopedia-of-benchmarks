from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer
@export("payback")
fn payback(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t) abi("C")->Int64:
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or n<1 or n>129 or v[0]<0 or v[0]>128 or Int(n)!=Int(v[0])+1:return -2
    var total:Int64=0
    for i in range(1,Int(n)):
        if v[i] < -1000000 or v[i]>1000000:return -2
        total+=v[i]
        if total>=0:return Int64(i-1)
    return -1
