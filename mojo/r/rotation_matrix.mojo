from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin,MutAnyOrigin,UnsafePointer
from math import sin,cos
@export("rotation_matrix")
fn rotation_matrix(v:UnsafePointer[Float64,ImmutAnyOrigin],n:c_size_t,o:UnsafePointer[Float64,MutAnyOrigin],cap:c_size_t) abi("C")->Int64:
    if v==UnsafePointer[Float64,ImmutAnyOrigin]() or n!=1 or not v[0].is_finite() or v[0]< -1000.0 or v[0]>1000.0:return -1
    let c=cos(v[0]);let s=sin(v[0]);if o==UnsafePointer[Float64,MutAnyOrigin]() or cap<4:return -2
    o[0]=c;o[1]= -s;o[2]=s;o[3]=c;return 4
