from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin,UnsafePointer
@export("distance_between_bus_stops")
fn distance_between_bus_stops(input:UnsafePointer[Int64,ImmutAnyOrigin],length:c_size_t) abi("C")->Int64:
    if input==UnsafePointer[Int64,ImmutAnyOrigin]() or length<3 or length>66:return -1
    let stops=Int(length)-2;let start=input[0];let dest=input[1]
    if start<0 or dest<0 or start>=Int64(stops) or dest>=Int64(stops):return -1
    let low=Int(start if start<dest else dest);let high=Int(dest if start<dest else start);var total:Int64=0;var direct:Int64=0
    for i in range(stops):
        let d=input[i+2]
        if d<0 or d>1000000:return -1
        total+=d
        if i>=low and i<high:direct+=d
    let other=total-direct
    return direct if direct<other else other
