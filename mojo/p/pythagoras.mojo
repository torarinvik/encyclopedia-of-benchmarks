from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer
from std.math import sqrt

@export("pythagoras")
fn pythagoras(values:UnsafePointer[Int64,ImmutAnyOrigin],length:c_size_t) abi("C")->Float64:
    if values==UnsafePointer[Int64,ImmutAnyOrigin]() or length!=6:return -1.0e300
    for i in range(6):
        if values[i]< -1000000 or values[i]>1000000:return -1.0e300
    let dx=Float64(values[3]-values[0]);let dy=Float64(values[4]-values[1]);let dz=Float64(values[5]-values[2])
    return sqrt(dx*dx+dy*dy+dz*dz)
