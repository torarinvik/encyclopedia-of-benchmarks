from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer
from std.math import sqrt
@export("herons_formula")
fn herons_formula(a:UnsafePointer[Float64,ImmutAnyOrigin],n:c_size_t) abi("C")->Float64:
    if a==UnsafePointer[Float64,ImmutAnyOrigin]() or n!=3:return -1.0
    let x=a[0];let y=a[1];let z=a[2]
    if x<1.0 or x>1000000.0 or y<1.0 or y>1000000.0 or z<1.0 or z>1000000.0:return -1.0
    if Float64(Int64(x))!=x or Float64(Int64(y))!=y or Float64(Int64(z))!=z:return -1.0
    if x+y<=z or x+z<=y or y+z<=x:return -1.0
    let s=(x+y+z)/2.0;return sqrt(s*(s-x)*(s-y)*(s-z))
