from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
from std.math import isfinite, sin, cos, sqrt
@export("projectile_motion")
fn projectile_motion(values:UnsafePointer[Float64,ImmutAnyOrigin],length:c_size_t,output:UnsafePointer[Float64,MutAnyOrigin],capacity:c_size_t) abi("C")->Int64:
    if values==UnsafePointer[Float64,ImmutAnyOrigin]() or length!=4:return -1
    for i in range(4):if !isfinite(values[i]):return -1
    let velocity=values[0];let angle=values[1];let height=values[2];let gravity=values[3]
    if velocity<0 or velocity>1000 or angle< -180 or angle>180 or height<0 or height>1000 or gravity<0.1 or gravity>20:return -1
    let radians=angle/180.0*3.14159265358979323846;let vy=velocity*sin(radians);let vx=velocity*cos(radians)
    let time=(vy+sqrt(vy*vy+2.0*gravity*height))/gravity
    let maxheight=height+(vy*vy/(2.0*gravity) if vy>0 else 0.0);let range=vx*time
    if output==UnsafePointer[Float64,MutAnyOrigin]() or capacity<3:return -2
    output[0]=time;output[1]=range;output[2]=maxheight
    return 3
