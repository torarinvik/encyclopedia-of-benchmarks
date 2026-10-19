from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin,MutAnyOrigin,UnsafePointer
from std.collections import List
from std.math import atan2,cos,sin
@export("dimensionality_reduction_pca")
fn dimensionality_reduction_pca(input:UnsafePointer[Float64,ImmutAnyOrigin],length:c_size_t,out:UnsafePointer[Float64,MutAnyOrigin],capacity:c_size_t) abi("C")->Int64:
    if input==UnsafePointer[Float64,ImmutAnyOrigin]() or length<7 or input[0]!=2.0 or input[2]!=1.0 or input[1]<2.0 or input[1]>8.0 or Float64(Int64(input[1]))!=input[1]:return -1
    let n=Int(input[1])
    if length!=c_size_t(3+2*n):return -1
    var x=List[Float64](capacity=8);var y=List[Float64](capacity=8);var mx:Float64=0.0;var my:Float64=0.0
    for i in range(n):
        let xv=input[3+i];let yv=input[3+n+i]
        if xv!=xv or yv!=yv or xv>1000000.0 or xv< -1000000.0 or yv>1000000.0 or yv< -1000000.0:return -1
        x.append(xv);y.append(yv);mx+=xv;my+=yv
    mx/=Float64(n);my/=Float64(n);var a:Float64=0.0;var b:Float64=0.0;var d:Float64=0.0
    for i in range(n):let dx=x[i]-mx;let dy=y[i]-my;a+=dx*dx;b+=dx*dy;d+=dy*dy
    a/=Float64(n);b/=Float64(n);d/=Float64(n)
    if b<=0.0 or abs(a-d)+abs(b)==0.0:return -1
    let angle=0.5*atan2(2.0*b,a-d);let vx=cos(angle);let vy=sin(angle);var staged=List[Float64](capacity=8)
    for i in range(n):staged.append(vx*x[i]+vy*y[i])
    if out==UnsafePointer[Float64,MutAnyOrigin]() or capacity<c_size_t(n):return -2
    for i in range(n):out[i]=staged[i]
    return Int64(n)
