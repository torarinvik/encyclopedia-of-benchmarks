from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin,MutAnyOrigin,UnsafePointer
from std.collections import InlineArray
from std.math import isfinite
@export("joint_probability_distribution")
fn joint_probability_distribution(v:UnsafePointer[Float64,ImmutAnyOrigin],n:c_size_t,o:UnsafePointer[Float64,MutAnyOrigin],cap:c_size_t) abi("C")->Int64:
    if v==UnsafePointer[Float64,ImmutAnyOrigin]() or n<2 or n>20:return -1
    for i in range(Int(n)):if not isfinite(v[i]):return -1
    if v[0]<1.0 or v[0]>4.0 or v[1]<1.0 or v[1]>4.0:return -1
    let nx=Int(v[0]);let ny=Int(v[1]);if Float64(nx)!=v[0] or Float64(ny)!=v[1] or n!=c_size_t(2+2*nx+2*ny):return -1
    let xs=2;let ys=xs+nx;let xp=ys+ny;let yp=xp+nx
    var xv=InlineArray[Int64,4](fill=0);var yv=InlineArray[Int64,4](fill=0)
    for i in range(nx):
        if v[xs+i]< -1000.0 or v[xs+i]>1000.0 or Float64(Int64(v[xs+i]))!=v[xs+i] or v[xp+i]< -1000000.0 or v[xp+i]>1000000.0:return -1
        xv[i]=Int64(v[xs+i])
        for j in range(i):if xv[j]==xv[i]:return -1
    for i in range(ny):
        if v[ys+i]< -1000.0 or v[ys+i]>1000.0 or Float64(Int64(v[ys+i]))!=v[ys+i] or v[yp+i]< -1000000.0 or v[yp+i]>1000000.0:return -1
        yv[i]=Int64(v[ys+i])
        for j in range(i):if yv[j]==yv[i]:return -1
    let required=3*nx*ny
    if o==UnsafePointer[Float64,MutAnyOrigin]() or cap<c_size_t(required):return -2
    var stage=InlineArray[Float64,48](fill=0.0);var pos=0
    for i in range(nx):
        for j in range(ny):stage[pos]=Float64(xv[i]);stage[pos+1]=Float64(yv[j]);stage[pos+2]=v[xp+i]*v[yp+j];pos+=3
    for i in range(required):o[i]=stage[i]
    return Int64(required)
