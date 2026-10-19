from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin,UnsafePointer
from math import sqrt
@export("rms_speed_of_molecule")
fn rms_speed_of_molecule(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t) abi("C")->Float64:
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or n!=2 or v[0]<0 or v[0]>1000 or v[1]<1 or v[1]>1000:return -1.0e300
    return sqrt(((3.0*8.3144598)*Float64(v[0]))/Float64(v[1]))
