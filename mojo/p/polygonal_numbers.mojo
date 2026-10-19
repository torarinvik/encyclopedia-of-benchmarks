from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer
@export("polygonal_numbers")
fn polygonal_numbers(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t) abi("C")->Int64:
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or n!=2 or v[0]<0 or v[0]>100000000 or v[1]<3 or v[1]>64:return -1
    let num=v[0];let sides=v[1]
    return ((sides-2)*num*num-(sides-4)*num)/2
