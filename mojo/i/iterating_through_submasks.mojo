from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

@export("iterating_through_submasks")
fn iterating_through_submasks(input:UnsafePointer[Int64,ImmutAnyOrigin],length:c_size_t) abi("C")->Int64:
    if input==UnsafePointer[Int64,ImmutAnyOrigin]() or length!=1 or input[0]<1 or input[0]>4095:return -1
    let mask=input[0];var sub=mask;var count:Int64=0
    while sub!=0:count+=1;sub=(sub-1)&mask
    return count
