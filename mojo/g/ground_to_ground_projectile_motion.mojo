from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer
from std.math import cos, pow, sin
@export("ground_to_ground_projectile_motion")
fn ground_to_ground_projectile_motion(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t) abi("C")->Float64:
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or n!=4:return -1.0e300
    let op=v[0];let sv=v[1];let av=v[2];let aux=v[3]
    if op<0 or op>2 or sv<0 or sv>1000000000 or av< -360000000 or av>360000000:return -1.0e300
    if op==1:
        if aux<0 or aux>1000000000:return -1.0e300
    elif aux<1000 or aux>100000000:return -1.0e300
    let speed=Float64(sv)/1000000.0;let angle=Float64(av)/1000000.0;let radians=angle*(3.14159265358979323846/180.0);let vy=speed*sin(radians)
    if op==0:return 2.0*vy/(Float64(aux)/1000000.0)
    if op==1:return (speed*cos(radians))*(Float64(aux)/1000000.0)
    return pow(vy,2.0)/(2.0*(Float64(aux)/1000000.0))
