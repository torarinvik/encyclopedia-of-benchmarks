from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin,UnsafePointer
@export("logTwo")
fn log_two(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t) abi("C")->Int64:
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or n!=1 or v[0]<0 or v[0]>2147483647:return -1
    var x=v[0];var r:Int64=0
    while (x>>1)!=0:x>>=1;r+=1
    return r
