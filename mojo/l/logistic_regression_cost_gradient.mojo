from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin,MutAnyOrigin,UnsafePointer
from std.math import exp,log
fn lr_put_f64(out:UnsafePointer[UInt8,MutAnyOrigin],at:Int,x:Float64):
    let b=bitcast[UInt64](x)
    for j in range(8):out[at+j]=UInt8((b>>(8*j))&255)
@export("logistic_regression_cost_gradient")
fn logistic_regression_cost_gradient(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t,out:UnsafePointer[UInt8,MutAnyOrigin],cap:c_size_t) abi("C")->Int64:
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or n<2:return -1
    let m=v[0];let d=v[1]
    if m<1 or m>64 or d<1 or d>8 or n!=c_size_t(2+m*d+d+m):return -1
    let toff=2+Int(m*d);let yoff=toff+Int(d)
    for i in range(Int(m*d+d)):
        if v[2+i]<-1000000 or v[2+i]>1000000:return -1
    for i in range(Int(m)):
        if v[yoff+i]!=0 and v[yoff+i]!=1:return -1
    let bytes=(Int(d)+1)*8
    if out==UnsafePointer[UInt8,MutAnyOrigin]() or cap<c_size_t(bytes):return -2
    var loss=0.0;var grad=InlineArray[Float64,8](fill=0.0)
    for s in range(Int(m)):
        var score=0.0
        for f in range(Int(d)):
            let x=Float64(v[2+s*Int(d)+f])/1.0e6;let theta=Float64(v[toff+f])/1.0e6;score+=x*theta
        let prob=1.0/(1.0+exp(-score));let label=Float64(v[yoff+s])
        loss+= -label*log(prob)-(1.0-label)*log(1.0-prob);let err=prob-label
        for f in range(Int(d)):grad[f]+=(err*(Float64(v[2+s*Int(d)+f])/1.0e6))
    lr_put_f64(out,0,loss/Float64(m))
    for f in range(Int(d)):lr_put_f64(out,(f+1)*8,grad[f]/Float64(m))
    return Int64(bytes)
