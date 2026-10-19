from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin,MutAnyOrigin,UnsafePointer
from math import pi,tan,ln,sqrt,abs,cos
@export("rhumb_distance")
fn rhumb_distance(v:UnsafePointer[Float64,ImmutAnyOrigin],n:c_size_t,o:UnsafePointer[Float64,MutAnyOrigin],cap:c_size_t) abi("C")->Int64:
    if v==UnsafePointer[Float64,ImmutAnyOrigin]() or n!=4:return -1
    let a=v[0];let b=v[1];let c=v[2];let d=v[3]
    if not a.is_finite() or not b.is_finite() or not c.is_finite() or not d.is_finite() or a< -85.0 or a>85.0 or c< -85.0 or c>85.0 or b< -180.0 or b>180.0 or d< -180.0 or d>180.0:return -1
    let p1=a*pi/180.0;let p2=c*pi/180.0;let dp=p2-p1;var dl=(d-b)*pi/180.0
    if dl>pi:dl-=2.0*pi
    elif dl< -pi:dl+=2.0*pi
    let dpsi=ln(tan(p2/2.0+pi/4.0)/tan(p1/2.0+pi/4.0));let q=if abs(dpsi)>1e-12:dp/dpsi else:cos(p1);let dist=sqrt(dp*dp+(q*dl)*(q*dl))*6371000.0
    if o==UnsafePointer[Float64,MutAnyOrigin]() or cap<1:return -2
    o[0]=dist;return 1
