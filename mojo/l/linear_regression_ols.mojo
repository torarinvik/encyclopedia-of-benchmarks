from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin,UnsafePointer
@export("linear_regression_ols")
fn linear_regression_ols(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t) abi("C")->Float64:
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or n<5 or n>257 or n%2==0:return -1.0e300
    let m=v[0]
    if m<2 or m>128 or n!=c_size_t(1+2*m):return -1.0e300
    var sx=0.0;var sy=0.0
    for i in range(Int(m)):
        let x=v[1+2*i];let y=v[2+2*i]
        if x < -1000000 or x>1000000 or y < -1000000 or y>1000000:return -1.0e300
        sx+=Float64(x);sy+=Float64(y)
    let mx=sx/Float64(m);let my=sy/Float64(m);var cov=0.0;var vx=0.0;var vy=0.0
    for i in range(Int(m)):
        let dx=Float64(v[1+2*i])-mx;let dy=Float64(v[2+2*i])-my
        cov+=dx*dy;vx+=dx*dx;vy+=dy*dy
    if vx<=1.0e-12 or vy<=1.0e-12:return -1.0e300
    return cov/vx
