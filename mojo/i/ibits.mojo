from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

@export("ibits")
fn ibits(input:UnsafePointer[Int64,ImmutAnyOrigin],length:c_size_t) abi("C")->Int64:
    if input==UnsafePointer[Int64,ImmutAnyOrigin]() or length!=1 or input[0]<0 or input[0]>=9007199254740992:return -1
    var x=input[0];var count:Int64=0
    while x!=0:count+=1;x>>=1
    return count
