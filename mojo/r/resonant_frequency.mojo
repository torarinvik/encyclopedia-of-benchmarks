from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin,UnsafePointer
from math import sqrt
@export("resonant_frequency")
fn resonant_frequency(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t) abi("C")->Float64:
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or n!=2:return -1.0e300
    if v[0]<1 or v[0]>1000 or v[1]<1 or v[1]>1000:return -1.0e300
    return 1.0/(2.0*3.14159265358979323846*sqrt(Float64(v[0])*Float64(v[1])))
