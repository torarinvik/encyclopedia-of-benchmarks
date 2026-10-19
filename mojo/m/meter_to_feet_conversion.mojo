from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer
@export("meter_to_feet_conversion")
fn meter_to_feet_conversion(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t) abi("C")->Float64:
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or n!=2:return -1.0e300
    if (v[0]!=0 and v[0]!=1) or v[1] < -1000000000 or v[1]>1000000000:return -1.0e300
    let value=Float64(v[1])/1000.0
    return value*0.3048 if v[0]==0 else value/0.3048
