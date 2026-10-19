from std.ffi import c_size_t
from std.math import sqrt
from std.memory import ImmutAnyOrigin, UnsafePointer
comptime BAD:Float64= -1.0e300
@export("speed_of_sound")
fn speed_of_sound(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t) abi("C")->Float64:
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or n!=2:return BAD
    if v[0]<1 or v[0]>1000 or v[1]<1 or v[1]>1000000000:return BAD
    return sqrt(Float64(v[1])/Float64(v[0]))
