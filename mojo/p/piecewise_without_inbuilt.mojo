from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
@export("piecewise_without_inbuilt")
fn piecewise_without_inbuilt(v:UnsafePointer[Float64,ImmutAnyOrigin],n:c_size_t,o:UnsafePointer[Float64,MutAnyOrigin],cap:c_size_t) abi("C")->Int64:
    if v==UnsafePointer[Float64,ImmutAnyOrigin]() or n!=1 or not is_finite(v[0]) or v[0] < -10.0 or v[0]>10.0:return -1
    let x=v[0];let y=0.0 if x<=-0.5 else (x if x<0.5 else 1.0)
    if o==UnsafePointer[Float64,MutAnyOrigin]() or cap<1:return -2
    o[0]=y;return 1
