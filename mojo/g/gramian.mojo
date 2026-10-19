from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
from std.collections import InlineArray
fn grm_put(out:UnsafePointer[UInt8,MutAnyOrigin],pos:Int,x:Float64):
    let bits=bitcast[UInt64](x)
    for b in range(8):out[pos+b]=UInt8((bits>>UInt64(8*b))&255)
fn grm_compute(v:UnsafePointer[Int64,ImmutAnyOrigin],c:Int,p:Int,part:Int,mut g:InlineArray[Float64,9]):
    let n=c*p
    for i in range(c):
        for j in range(c):
            var dot=0.0
            for k in range(p):dot+=(Float64(v[3+part*n+i*p+k])/1000.0)*(Float64(v[3+part*n+j*p+k])/1000.0)
            g[i*c+j]=dot/Float64(n)
@export("gramian")
fn gramian(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t,out:UnsafePointer[UInt8,MutAnyOrigin],cap:c_size_t) abi("C")->Int64:
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or n<3 or n>27:return -1
    let op=Int(v[0]);let c=Int(v[1]);let p=Int(v[2])
    if (op!=0 and op!=1) or c<1 or c>3 or p<1 or p>4 or n!=c_size_t(3+c*p*(1 if op==0 else 2)):return -1
    for i in range(3,Int(n)):if v[i]< -1000 or v[i]>1000:return -1
    let count=1 if op==1 else c*c;let bytes=count*8
    if out==UnsafePointer[UInt8,MutAnyOrigin]() or cap<c_size_t(bytes):return -2
    var a=InlineArray[Float64,9](fill=0.0);var b=InlineArray[Float64,9](fill=0.0);var result=InlineArray[Float64,9](fill=0.0)
    grm_compute(v,c,p,0,a)
    if op==1:
        grm_compute(v,c,p,1,b);var loss=0.0
        for i in range(c*c):let d=a[i]-b[i];loss+=d*d
        result[0]=loss
    else:
        for i in range(c*c):result[i]=a[i]
    for i in range(count):grm_put(out,i*8,result[i])
    return Int64(bytes)
