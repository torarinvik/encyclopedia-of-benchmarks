from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer
comptime BAD:Float64=-1.0e300
fn sift_down(a:InlineArray[Float64,64],start:Int,end:Int)->InlineArray[Float64,64]:
    var v=a;var root=start
    while root<end/2:
        var child=root*2+1
        if child+1<end and v[child]<v[child+1]:child+=1
        if v[root]>=v[child]:break
        let t=v[root];v[root]=v[child];v[child]=t;root=child
    return v
@export("value_at_risk")
fn value_at_risk(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t) abi("C")->Float64:
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or n<2 or n>67:return BAD
    let confidence=v[0];let countv=v[1]
    if confidence<1 or confidence>=1000000 or countv<1 or countv>64 or n!=c_size_t(2+countv):return BAD
    var values=InlineArray[Float64,64](fill=0.0)
    for i in range(Int(countv)):
        if v[2+i]< -1000000000 or v[2+i]>1000000000:return BAD
        values[i]=Float64(v[2+i])/1000000.0
    let count=Int(countv)
    for startstep in range(count/2):
        let start=count/2-1-startstep
        values=sift_down(values,start,count)
    for step in range(count-1):
        let end=count-step
        let t=values[0];values[0]=values[end-1];values[end-1]=t
        values=sift_down(values,0,end-1)
    let conf=Float64(confidence)/1000000.0;let pos=Float64(count-1)*(1.0-conf)
    let lower=Int(pos);let fraction=pos-Float64(lower)
    let quant=values[count-1] if lower==count-1 else values[lower]*(1.0-fraction)+values[lower+1]*fraction
    return -quant
