from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin,MutAnyOrigin,UnsafePointer
from math import pi,tan,ln,sin,cos
@export("rhumb_destination")
fn rhumb_destination(v:UnsafePointer[Float64,ImmutAnyOrigin],n:c_size_t,o:UnsafePointer[Float64,MutAnyOrigin],cap:c_size_t) abi("C")->Int64:
    if v==UnsafePointer[Float64,ImmutAnyOrigin]() or n!=4:return -1
    let lat=v[0];let lon=v[1];let dist=v[2];let bear=v[3]
    if not lat.is_finite() or not lon.is_finite() or not dist.is_finite() or not bear.is_finite() or lat< -80.0 or lat>80.0 or lon< -180.0 or lon>180.0 or dist<0.0 or dist>300000.0 or bear<0.0 or bear>360.0:return -1
    let delta=dist/6371000.0;let p1=lat*pi/180.0;let l1=lon*pi/180.0;let theta=bear*pi/180.0;let dp=delta*cos(theta);var p2=p1+dp
    if p2>pi/2.0:p2=pi/2.0
    elif p2< -pi/2.0:p2= -pi/2.0
    let dpsi=ln(tan(p2/2.0+pi/4.0)/tan(p1/2.0+pi/4.0));let q=if abs(dpsi)>1e-12:dp/dpsi else:cos(p1);let dl=delta*sin(theta)/q
    let lat2=p2*180.0/pi;let lon2=(l1+dl)*180.0/pi
    if o==UnsafePointer[Float64,MutAnyOrigin]() or cap<2:return -2
    o[0]=lat2;o[1]=lon2;return 2
