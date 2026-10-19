from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin,UnsafePointer
from std.math import abs,atan,floor,sqrt,tan
@export("light_aberration")
fn light_aberration(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t) abi("C")->Float64:
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or n!=2 or v[0]<-3141592 or v[0]>3141592 or v[1]<0 or v[1]>999999:return -1.0e300
    let theta=Float64(v[0])/1.0e6;let beta=Float64(v[1])/1.0e6
    let factor=sqrt((1.0-beta)/(1.0+beta));let angle=2.0*atan(factor*tan(theta/2.0));let scaled=angle*100000.0
    let frac=scaled-floor(scaled)
    if abs(frac-0.5)<=1.0e-7:return -1.0e300
    let mag=abs(angle);let rounded=floor(mag*100000.0+0.5)/100000.0
    return if angle<0.0:-rounded else:rounded
