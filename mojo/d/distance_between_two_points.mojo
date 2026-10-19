from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin,UnsafePointer
from std.math import sqrt
@export("distance_between_two_points")
fn distance_between_two_points(input:UnsafePointer[Int64,ImmutAnyOrigin],length:c_size_t) abi("C")->Float64:
    if input==UnsafePointer[Int64,ImmutAnyOrigin]() or length!=4:return -1.0e300
    for i in range(4):if input[i]< -1000000 or input[i]>1000000:return -1.0e300
    let dx=Float64(input[2]-input[0]);let dy=Float64(input[3]-input[1])
    return sqrt(dx*dx+dy*dy)
