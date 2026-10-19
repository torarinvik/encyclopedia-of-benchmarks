from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
from std.math import abs, isfinite, sqrt
@export("gravitational_force")
fn gravitational_force(v:UnsafePointer[Float64,ImmutAnyOrigin],n:c_size_t,out:UnsafePointer[Float64,MutAnyOrigin],cap:c_size_t) abi("C")->Int64:
    if v==UnsafePointer[Float64,ImmutAnyOrigin]() or n!=6:return -1
    for i in range(6):if not isfinite(v[i]):return -1
    let m1=v[0];let x1=v[1];let y1=v[2];let m2=v[3];let x2=v[4];let y2=v[5]
    if abs(m1)>1.0e12 or abs(m2)>1.0e12 or (m1!=0.0 and abs(m1)<1.0e-12) or (m2!=0.0 and abs(m2)<1.0e-12) or abs(x1)>1.0e6 or abs(y1)>1.0e6 or abs(x2)>1.0e6 or abs(y2)>1.0e6:return -1
    let dx=x1-x2;let dy=y1-y2;let d2=dx*dx+dy*dy
    if d2!=0.0 and d2<1.0e-12:return -1
    if out==UnsafePointer[Float64,MutAnyOrigin]() or cap<2:return -2
    if d2==0.0:out[0]=0.0;out[1]=0.0;return 2
    let distance=sqrt(d2);let mag=6.67430e-11*m1*m2/d2
    out[0]=mag*(dx/distance);out[1]=mag*(dy/distance);return 2
