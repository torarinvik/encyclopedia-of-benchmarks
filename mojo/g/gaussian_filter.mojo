from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
from std.collections import InlineArray

fn gf_weight(k:Int,d:Int)->Int64:
    if k==3:
        if d==0:return 159154943091895
        if d==1:return 96532352630054
        return 58549831524319
    if d==0:return 198943678864869
    if d==1:return 91083053297916
    if d==2:return 41700860491808
    if d==4:return 8740975213082
    if d==5:return 4001910066968
    return 384051647741

@export("gaussian_filter")
fn gaussian_filter(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t,out:UnsafePointer[UInt8,MutAnyOrigin],cap:c_size_t) abi("C")->Int64:
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or n<3:return -1
    let h=Int(v[0]);let w=Int(v[1]);let k=Int(v[2])
    if h<3 or h>12 or w<3 or w>12 or (k!=3 and k!=5) or h<k or w<k or n!=c_size_t(3+h*w):return -1
    for i in range(3,Int(n)):if v[i]<0 or v[i]>255:return -1
    let oh=h-k+1;let ow=w-k+1;let count=oh*ow
    if out==UnsafePointer[UInt8,MutAnyOrigin]() or cap<c_size_t(count):return -2
    var stage=InlineArray[UInt8,100](fill=0);let center=k//2
    for r in range(oh):
        for c in range(ow):
            var total:Int64=0
            for kr in range(k):
                let dy=kr-center
                for kc in range(k):
                    let dx=kc-center;let index=3+(r+kr)*w+c+kc
                    total+=v[index]*gf_weight(k,dx*dx+dy*dy)
            stage[r*ow+c]=UInt8(total//1000000000000000)
    for i in range(count):out[i]=stage[i]
    return Int64(count)
