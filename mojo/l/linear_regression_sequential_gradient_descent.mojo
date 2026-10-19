from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin,UnsafePointer
@export("linear_regression_sequential_gradient_descent")
fn linear_regression_sequential_gradient_descent(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t) abi("C")->Float64:
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or n<7 or n>131 or n%2==0:return -1.0e300
    let m=v[0];let rate=v[1];let epochs=v[2]
    if m<2 or m>64 or n!=c_size_t(3+2*m) or rate<1 or rate>1000 or epochs<1 or epochs>10000:return -1.0e300
    for i in range(Int(m)):
        if v[3+2*i]<-10 or v[3+2*i]>10 or v[4+2*i]<-100 or v[4+2*i]>100:return -1.0e300
    let scale=(Float64(rate)/1.0e6)/Float64(m);var slope=0.0;var intercept=0.0;var cost=0.0
    for _ in range(Int(epochs)):
        var gs=0.0
        for i in range(Int(m)):gs+=(slope*Float64(v[3+2*i])+intercept-Float64(v[4+2*i]))*Float64(v[3+2*i])
        slope-=scale*gs
        var gb=0.0
        for i in range(Int(m)):gb+=slope*Float64(v[3+2*i])+intercept-Float64(v[4+2*i])
        intercept-=scale*gb;cost=0.0
        for i in range(Int(m)):
            let e=slope*Float64(v[3+2*i])+intercept-Float64(v[4+2*i]);cost+=e*e
        cost/=2.0*Float64(m)
    return cost
