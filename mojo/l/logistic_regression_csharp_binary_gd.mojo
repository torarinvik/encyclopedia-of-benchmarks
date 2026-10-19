from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin,UnsafePointer
from std.math import exp
@export("logistic_regression_csharp_binary_gd")
fn logistic_regression_csharp_binary_gd(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t) abi("C")->Float64:
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or n<4:return -1.0e300
    let m=v[0];let d=v[1];let epochs=v[2];let rate=v[3]
    if m<1 or m>32 or d<1 or d>8 or epochs<0 or epochs>128 or rate<1 or rate>100000:return -1.0e300
    let labels=4+Int(m*d);let query=labels+Int(m)
    if n!=c_size_t(query+Int(d)):return -1.0e300
    for i in range(Int(m*d)):
        if v[4+i] < -1000000 or v[4+i]>1000000:return -1.0e300
    for i in range(Int(m)):
        if v[labels+i]!=0 and v[labels+i]!=1:return -1.0e300
    for i in range(Int(d)):
        if v[query+i] < -1000000 or v[query+i]>1000000:return -1.0e300
    var w=InlineArray[Float64,8](fill=0.0);var nw=InlineArray[Float64,8](fill=0.0);var errors=InlineArray[Float64,32](fill=0.0);var bias=0.0;let alpha=Float64(rate)/1.0e6
    for _ in range(Int(epochs)):
        var bg=0.0
        for s in range(Int(m)):
            var dot=0.0
            for f in range(Int(d)):dot+=(Float64(v[4+s*Int(d)+f])/1.0e6)*w[f]
            let prediction=1.0/(1.0+exp(-(dot+bias)));errors[s]=prediction-Float64(v[labels+s]);bg+=errors[s]
        for f in range(Int(d)):
            var grad=0.0
            for s in range(Int(m)):grad+=errors[s]*(Float64(v[4+s*Int(d)+f])/1.0e6)
            nw[f]=w[f]-alpha*grad/Float64(m)
        for f in range(Int(d)):w[f]=nw[f]
        bias-=alpha*bg/Float64(m)
    var dot=0.0
    for f in range(Int(d)):dot+=(Float64(v[query+f])/1.0e6)*w[f]
    return 1.0/(1.0+exp(-(dot+bias)))
