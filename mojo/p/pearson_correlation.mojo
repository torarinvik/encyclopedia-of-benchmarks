from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer
@export("pearson_correlation")
fn pearson_correlation(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t) abi("C")->Float64:
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or n<5 or n>257 or v[0]<2 or v[0]>128 or Int(n)!=1+2*Int(v[0]):return -1.0e300
    let count=Int(v[0]);var sx=0.0;var sy=0.0
    for i in range(count):let x=v[1+i];let y=v[1+count+i];if x < -1000000 or x>1000000 or y < -1000000 or y>1000000:return -1.0e300;sx+=Float64(x);sy+=Float64(y)
    let mx=sx/Float64(count);let my=sy/Float64(count);var cov=0.0;var vx=0.0;var vy=0.0
    for i in range(count):let dx=Float64(v[1+i])-mx;let dy=Float64(v[1+count+i])-my;cov+=dx*dy;vx+=dx*dx;vy+=dy*dy
    if vx==0.0 or vy==0.0:return -1.0e300
    return cov/sqrt(vx*vy)
