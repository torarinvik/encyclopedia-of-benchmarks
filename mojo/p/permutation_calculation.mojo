from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer
@export("permutation_calculation")
fn permutation_calculation(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t) abi("C")->Int64:
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or n!=2 or v[0]<0 or v[0]>15 or v[1]<0 or v[1]>v[0]:return -1
    var a:Int64=1;for i in range(1,Int(v[0])+1):a*=Int64(i)
    var b:Int64=1;for i in range(1,Int(v[0]-v[1])+1):b*=Int64(i)
    return a/b
