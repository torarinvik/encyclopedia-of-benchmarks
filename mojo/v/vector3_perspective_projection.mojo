from std.ffi import c_size_t
from std.math import isfinite
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
@export("vector3_perspective_projection")
fn vector3_perspective_projection(v:UnsafePointer[Float64,ImmutAnyOrigin],n:c_size_t,o:UnsafePointer[Float64,MutAnyOrigin],cap:c_size_t) abi("C")->Int64:
    if v==UnsafePointer[Float64,ImmutAnyOrigin]() or n!=5:return -1
    for i in range(5):
        if not isfinite(v[i]) or abs(v[i])>1000000.0:return -1
    let den=v[2]+v[4]
    if abs(den)<1e-6:return -1
    let x=((v[0]*v[4])/den)*v[3];let y=((v[1]*v[4])/den)*v[3]
    if not isfinite(x) or not isfinite(y) or abs(x)>1e25 or abs(y)>1e25:return -1
    if o==UnsafePointer[Float64,MutAnyOrigin]() or cap<2:return -2
    o[0]=x;o[1]=y;return 2
