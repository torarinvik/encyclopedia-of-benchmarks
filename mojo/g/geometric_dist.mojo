from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer
from std.collections import InlineArray
from std.math import log, pow, sqrt
fn gd_cdf(p:Float32,k:Int)->Float32:return Float32(1.0)-pow(Float32(1.0)-p,Float32(k))
@export("geometric_dist")
fn geometric_dist(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t) abi("C")->Float64:
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or n<2:return -1.0e300
    let op=v[0];let pc=v[1];if pc<0 or pc>2:return -1.0e300
    let ps=InlineArray[Float32,3](0.25,0.5,0.75);let p=ps[Int(pc)]
    if op>=0 and op<=2:
        if n!=2:return -1.0e300
        if op==0:return Float64(Float32(1.0)/p)
        let variance=Float32((Float32(1.0)-p)/(p*p))
        if op==1:return Float64(variance)
        return Float64(sqrt(variance))
    if op==3 or op==4:
        if n!=3:return -1.0e300
        let k=Int(v[2])
        if (op==3 and (k<1 or k>16)) or (op==4 and (k<0 or k>16)):return -1.0e300
        if op==3:return Float64(pow(Float32(1.0)-p,Float32(k-1))*p)
        return Float64(gd_cdf(p,k))
    if op==5:
        if n!=3 or v[2]<0 or v[2]>2:return -1.0e300
        let cdfs=InlineArray[Float32,3](0.25,0.5,0.75);return Float64(log(Float64(Float32(1.0)-cdfs[Int(v[2]]))/Float64(Float32(1.0)-p)))
    if op==6:
        if n!=4:return -1.0e300
        let lo=Int(v[2]);let hi=Int(v[3]);if lo<1 or hi<lo or hi>16:return -1.0e300
        return Float64(gd_cdf(p,hi)-gd_cdf(p,lo-1))
    return -1.0e300
