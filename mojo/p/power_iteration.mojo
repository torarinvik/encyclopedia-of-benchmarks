from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer
from std.math import sqrt, fabs
@export("power_iteration")
fn power_iteration(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t) abi("C")->Float64:
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or n!=5:return -1.0e300
    for i in range(5):if v[i]<1 or v[i]>1000:return -1.0e300
    let a=Float64(v[0]);let b=Float64(v[1]);let d=Float64(v[2])
    if a*d<=b*b:return -1.0e300
    var x=Float64(v[3]);var y=Float64(v[4]);var prev=0.0
    for it in range(100):
        let w0=a*x+b*y;let w1=b*x+d*y;let norm=sqrt(w0*w0+w1*w1)
        if norm==0:return -1.0e300
        x=w0/norm;y=w1/norm
        let av0=a*x+b*y;let av1=b*x+d*y;let eig=x*av0+y*av1
        let err=fabs(eig-prev)/eig
        if err<=1e-12 or it==99:return eig
        prev=eig
    return -1.0e300
