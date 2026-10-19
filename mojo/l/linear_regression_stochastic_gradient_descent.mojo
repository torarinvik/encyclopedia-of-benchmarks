from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin,UnsafePointer
@export("linear_regression_stochastic_gradient_descent")
fn linear_regression_stochastic_gradient_descent(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t) abi("C")->Float64:
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or n<9 or n>133:return -1.0e300
    let m=v[0];let epochs=v[1];let rate=v[2];let m0=v[3];let b0=v[4]
    if m<2 or m>64 or n!=c_size_t(5+2*m) or epochs<1 or epochs>200 or rate<1 or rate>10000 or m0 < -10000000 or m0>10000000 or b0 < -10000000 or b0>10000000:return -1.0e300
    for i in range(Int(m)):
        if v[5+2*i] < -10000000 or v[5+2*i]>10000000 or v[6+2*i] < -100000000 or v[6+2*i]>100000000:return -1.0e300
    let alpha=Float64(rate)/1.0e6;var w=Float64(m0)/1.0e6;var b=Float64(b0)/1.0e6
    for _ in range(Int(epochs)):
        for i in range(Int(m)):
            let x=Float64(v[5+2*i])/1.0e6;let y=Float64(v[6+2*i])/1.0e6;let e=w*x+b-y
            let gw=e*x/Float64(m);let gb=e/Float64(m);w-=alpha*gw;b-=alpha*gb
    return w
