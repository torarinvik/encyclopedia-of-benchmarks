from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin,UnsafePointer
@export("linear_regression_gradient_descent")
fn linear_regression_gradient_descent(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t) abi("C")->Float64:
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or n<7 or n>131 or n%2==0:return -1.0e300
    let count=v[0];let rate=v[1];let epochs=v[2]
    if count<2 or count>64 or n!=c_size_t(3+2*count) or rate<1 or rate>1000 or epochs<1 or epochs>10000:return -1.0e300
    for i in range(Int(count)):
        if v[3+2*i]<-10 or v[3+2*i]>10 or v[4+2*i]<-100 or v[4+2*i]>100:return -1.0e300
    let alpha=Float64(rate)/1.0e6;let scale=alpha/Float64(count);var slope=0.0;var intercept=0.0
    for _ in range(Int(epochs)):
        var gs=0.0;var gi=0.0
        for i in range(Int(count)):
            let x=Float64(v[3+2*i]);let y=Float64(v[4+2*i]);let e=slope*x+intercept-y
            gs+=e*x;gi+=e
        slope-=scale*gs;intercept-=scale*gi
    return slope
