from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
from std.collections import InlineArray
from std.math import abs

fn gs_put(out:UnsafePointer[UInt8,MutAnyOrigin],pos:Int,x:Float64):
    let bits=bitcast[UInt64](x)
    for b in range(8):out[pos+b]=UInt8((bits>>UInt64(8*b))&255)

@export("gauss_seidel_method")
fn gauss_seidel_method(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t,out:UnsafePointer[UInt8,MutAnyOrigin],cap:c_size_t) abi("C")->Int64:
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or n<1 or v[0]<1 or v[0]>8:return -1
    let d=Int(v[0]);if n!=c_size_t(1+d*d+d):return -1
    for k in range(1,Int(n)):if v[k]< -1000000000 or v[k]>1000000000:return -1
    for r in range(d):
        let diagonal=v[1+r*d+r];if diagonal<=0:return -1
        var sum:Int64=0
        for c in range(d):
            if v[1+r*d+c]!=v[1+c*d+r]:return -1
            if c!=r:
                if v[1+r*d+c]<0:sum-=v[1+r*d+c]
                else:sum+=v[1+r*d+c]
        if diagonal<=sum:return -1
    if out==UnsafePointer[UInt8,MutAnyOrigin]() or cap<c_size_t(d*8):return -2
    var a=InlineArray[Float64,64](fill=0.0);var b=InlineArray[Float64,8](fill=0.0);var x=InlineArray[Float64,8](fill=0.0)
    for i in range(d*d):a[i]=Float64(v[i+1])/1000000.0
    for i in range(d):b[i]=Float64(v[1+d*d+i])/1000000.0
    for it in range(1000):
        var old=InlineArray[Float64,8](fill=0.0)
        for i in range(d):old[i]=x[i]
        for i in range(d):
            var before=0.0;var after=0.0
            for j in range(i):before+=a[i*d+j]*x[j]
            for j in range(i+1,d):after+=a[i*d+j]*old[j]
            x[i]=(b[i]-before-after)/a[i*d+i]
        var done=True
        for i in range(d):if abs(x[i]-old[i])>=1.0e-10:done=False
        if done:break
    for i in range(d):
        let scaled=x[i]*1.0e10
        let rounded=Float64(Int64(scaled+ (0.5 if scaled>=0.0 else -0.5)))/1.0e10
        gs_put(out,i*8,rounded)
    return Int64(d*8)
