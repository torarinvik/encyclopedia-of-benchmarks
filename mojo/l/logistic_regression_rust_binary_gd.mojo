from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin,MutAnyOrigin,UnsafePointer
from std.math import exp
fn logistic_rust_put(out:UnsafePointer[UInt8,MutAnyOrigin],slot:Int,x:Float64):
    let b=bitcast[UInt64](x)
    for j in range(8):out[slot*8+j]=UInt8((b>>(8*j))&255)
@export("logistic_regression_rust_binary_gd")
fn logistic_regression_rust_binary_gd(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t,out:UnsafePointer[UInt8,MutAnyOrigin],cap:c_size_t) abi("C")->Int64:
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or n<4:return -1
    let m=v[0];let d=v[1];let epochs=v[2];let rate=v[3]
    if m<1 or m>32 or d<1 or d>8 or epochs<0 or epochs>128 or rate<1 or rate>100000 or n!=c_size_t(4+m*d+m):return -1
    let yoff=4+Int(m*d)
    for i in range(Int(m*d)):
        if v[4+i] < -1000000 or v[4+i]>1000000:return -1
    for i in range(Int(m)):
        if v[yoff+i]<0 or v[yoff+i]>1000000:return -1
    let bytes=(Int(d)+1)*8
    if out==UnsafePointer[UInt8,MutAnyOrigin]() or cap<c_size_t(bytes):return -2
    var theta=InlineArray[Float64,9](fill=0.0);var grad=InlineArray[Float64,9](fill=0.0);var next=InlineArray[Float64,9](fill=0.0);let alpha=Float64(rate)/1.0e6
    for _ in range(Int(epochs)):
        for p in range(Int(d)+1):grad[p]=0.0
        for s in range(Int(m)):
            var score=theta[0]
            for f in range(Int(d)):score+=(Float64(v[4+s*Int(d)+f])/1.0e6)*theta[f+1]
            let prediction=1.0/(1.0+exp(-score));let error=prediction-Float64(v[yoff+s])/1.0e6
            grad[0]+=error
            for f in range(Int(d)):grad[f+1]+=error*(Float64(v[4+s*Int(d)+f])/1.0e6)
        for p in range(Int(d)+1):next[p]=theta[p]-alpha*grad[p]
        for p in range(Int(d)+1):theta[p]=next[p]
    for p in range(Int(d)+1):logistic_rust_put(out,p,theta[p])
    return Int64(bytes)
