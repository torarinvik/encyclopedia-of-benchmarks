from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer
@export("nimply_gate")
fn nimply_gate(a:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t) abi("C")->Int64:
    if a==UnsafePointer[Int64,ImmutAnyOrigin]() or n!=2:return -1
    if (a[0]!=0 and a[0]!=1) or (a[1]!=0 and a[1]!=1):return -1
    return 1 if a[0]==1 and a[1]==0 else 0
