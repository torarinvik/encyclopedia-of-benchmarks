from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer
from std.math import sqrt

@export("pyramid")
fn pyramid(values:UnsafePointer[Int64,ImmutAnyOrigin],length:c_size_t) abi("C")->Float64:
    if values==UnsafePointer[Int64,ImmutAnyOrigin]() or length!=3:return -1.0e300
    let operation=values[0];let base_raw=values[1];let height_raw=values[2]
    if operation<0 or operation>1 or base_raw<1 or base_raw>10000000 or height_raw<1 or height_raw>10000000:return -1.0e300
    let base=Float64(base_raw)/1000.0;let height=Float64(height_raw)/1000.0
    let base_area=base*base
    if operation==0:return base_area*height/3.0
    let half=base/2.0
    return base_area+2.0*base*sqrt(half*half+height*height)
