from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer
@export("permutation_count")
fn permutation_count(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t) abi("C")->Int64:
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or n!=2 or v[0]<0 or v[0]>18 or v[1]<0 or v[1]>18:return -1
    let a=v[0];let r=v[1];var result:Int64=1
    if r>a:for i in range(2,Int(a)+1):result*=Int64(i)
    else:for i in range(Int(r)):result*=a-Int64(i)
    return result
