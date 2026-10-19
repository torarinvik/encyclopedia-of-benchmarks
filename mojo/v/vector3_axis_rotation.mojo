from std.ffi import c_size_t
from std.math import cos, floor, isfinite, sin
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
comptime PI:Float64=3.14159265358979323846
@export("vector3_axis_rotation")
fn vector3_axis_rotation(v:UnsafePointer[Float64,ImmutAnyOrigin],n:c_size_t,o:UnsafePointer[Float64,MutAnyOrigin],cap:c_size_t) abi("C")->Int64:
    if v==UnsafePointer[Float64,ImmutAnyOrigin]() or n!=5:return -1
    for i in range(3):if not isfinite(v[i]) or abs(v[i])>1000000.0:return -1
    let axis=v[3];var angle=v[4]
    if not isfinite(axis) or (axis!=0.0 and axis!=1.0 and axis!=2.0) or not isfinite(angle) or abs(angle)>1000000.0:return -1
    angle-=floor(angle/360.0)*360.0
    if angle==0.0:angle=0.0
    angle=angle/450.0*180.0/PI
    let x=v[0];let y=v[1];let z=v[2];let c=cos(angle);let s=sin(angle)
    var result=InlineArray[Float64,3](fill=0.0)
    if axis==0.0:result[0]=x;result[1]=y*c-z*s;result[2]=z*c+y*s
    elif axis==1.0:result[0]=x*c-z*s;result[1]=y;result[2]=z*c+x*s
    else:result[0]=x*c-y*s;result[1]=y*c+x*s;result[2]=z
    for i in range(3):if not isfinite(result[i]) or abs(result[i])>2000000.0:return -1
    if o==UnsafePointer[Float64,MutAnyOrigin]() or cap<3:return -2
    for i in range(3):o[i]=result[i]
    return 3
