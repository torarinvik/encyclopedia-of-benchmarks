from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer
comptime BAD:Float64= -1.0e300
fn avg_rank(v:UnsafePointer[Int64,ImmutAnyOrigin],start:Int,n:Int,index:Int)->Float64:
    let x=v[start+index];var less=0;var equal=0
    for j in range(n):
        let y=v[start+j]
        if y<x:less+=1
        if y==x:equal+=1
    return Float64(less)+(Float64(equal)+1.0)/2.0
@export("spearman_average_rank_correlation")
fn spearman_average_rank_correlation(v:UnsafePointer[Int64,ImmutAnyOrigin],length:c_size_t) abi("C")->Float64:
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or length<5 or length>257:return BAD
    let nv=v[0]
    if nv<2 or nv>128 or length!=c_size_t(1+2*nv):return BAD
    let count=Int(nv)
    for i in range(1,Int(length)):if v[i]< -1000000 or v[i]>1000000:return BAD
    let ystart=1+count;let mean=(Float64(count)+1.0)/2.0
    var cov=0.0;var vx=0.0;var vy=0.0
    for i in range(count):
        let dx=avg_rank(v,1,count,i)-mean;let dy=avg_rank(v,ystart,count,i)-mean
        cov+=dx*dy;vx+=dx*dx;vy+=dy*dy
    if vx==0.0 or vy==0.0:return BAD
    return cov/sqrt(vx*vy)
