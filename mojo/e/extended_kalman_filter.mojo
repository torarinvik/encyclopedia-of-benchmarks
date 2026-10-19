from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

fn ekf_finite(x:Float64)->Bool:
    return x==x and x<1.0e300 and x> -1.0e300
@export("extended_kalman_filter")
fn extended_kalman_filter(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t) abi("C")->Float64:
    let bad= -1.0e300
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or n<10 or n>17:return bad
    let steps=v[0]
    if steps<1 or steps>8 or n!=c_size_t(9+steps):return bad
    for i in range(1,9):if v[i]< -10000 or v[i]>10000:return bad
    for i in range(9,Int(n)):if v[i]< -10000 or v[i]>10000:return bad
    let scale=1000.0
    var x=Float64(v[1])/scale;var y=Float64(v[2])/scale
    var p00=Float64(v[3])/scale;var p01=Float64(v[4])/scale;var p11=Float64(v[5])/scale
    let q0=Float64(v[6])/scale;let q1=Float64(v[7])/scale;let r=Float64(v[8])/scale
    if v[1]< -2000 or v[1]>2000 or v[2]< -2000 or v[2]>2000 or p00<=0.0 or p11<=0.0 or p00*p11<=p01*p01 or q0<0.0 or q1<0.0 or r<=0.0 or r>10.0:return bad
    for t in range(Int(steps)):
        let f01=0.1;let f10=0.1;let nx=x+f01*y;let ny=y+0.05*x*x
        let a=p00+2.0*f01*p01+f01*f01*p11+q0
        let b=f10*p00+(1.0+f01*f10)*p01+f01*p11
        let c=f10*f10*p00+2.0*f10*p01+p11+q1
        x=nx;y=ny;p00=a;p01=b;p11=c
        let h0=0.1*x;let predicted=0.05*x*x+y;let residual=Float64(v[9+t])/scale-predicted
        let innovation=h0*h0*p00+2.0*h0*p01+p11+r
        if not ekf_finite(innovation) or innovation<=0.0:return bad
        let k0=(p00*h0+p01)/innovation;let k1=(p01*h0+p11)/innovation
        x+=k0*residual;y+=k1*residual
        let a00=1.0-k0*h0;let a01= -k0;let a10= -k1*h0;let a11=1.0-k1
        let z00=a00*a00*p00+2.0*a00*a01*p01+a01*a01*p11+k0*k0*r
        let z01=a00*a10*p00+(a00*a11+a01*a10)*p01+a01*a11*p11+k0*k1*r
        let z11=a10*a10*p00+2.0*a10*a11*p01+a11*a11*p11+k1*k1*r
        p00=z00;p01=z01;p11=z11
        if not ekf_finite(x) or not ekf_finite(y) or not ekf_finite(p00) or not ekf_finite(p01) or not ekf_finite(p11):return bad
    return x
