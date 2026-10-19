from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin,UnsafePointer
from math import abs
fn even_round(x:Float64)->Int64:
    let base=Int64(x);let d=x-Float64(base)
    if d<0.5:return base
    if d>0.5:return base+1
    return if base%2==0:base else:base+1
@export("rgbhsvconversion")
fn rgbhsvconversion(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t) abi("C")->Int64:
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or n!=4:return -1
    if v[0]==0:
        if v[1]<0 or v[1]>360000 or v[2]<0 or v[2]>1000 or v[3]<0 or v[3]>1000:return -1
        let h=Float64(v[1])/1000.0;let s=Float64(v[2])/1000.0;let val=Float64(v[3])/1000.0;let c=val*s;let sec=h/60.0;let x=c*(1.0-abs((sec%2.0)-1.0));let m=val-c
        var r=val;var g=val;var b=val
        if sec<=1.0:r=c+m;g=x+m;b=m
        elif sec<=2.0:r=x+m;g=c+m;b=m
        elif sec<=3.0:r=m;g=c+m;b=x+m
        elif sec<=4.0:r=m;g=x+m;b=c+m
        elif sec<=5.0:r=x+m;g=m;b=c+m
        else:r=c+m;g=m;b=x+m
        return (even_round(255.0*r)<<16)|(even_round(255.0*g)<<8)|even_round(255.0*b)
    if v[0]!=1 or v[1]<0 or v[1]>255 or v[2]<0 or v[2]>255 or v[3]<0 or v[3]>255:return -1
    let r=Float64(v[1])/255.0;let g=Float64(v[2])/255.0;let b=Float64(v[3])/255.0
    let mx=if r>g:if r>b:r else:b else:if g>b:g else:b;let mn=if r<g:if r<b:r else:b else:if g<b:g else:b;let c=mx-mn
    let s=if mx==0.0:0.0 else:c/mx
    var h:Float64=0.0
    if c!=0.0:
        if mx==r:h=60.0*((g-b)/c)
        elif mx==g:h=60.0*(2.0+(b-r)/c)
        else:h=60.0*(4.0+(r-g)/c)
    h=(h+360.0)%360.0
    return (even_round(h*1000.0)<<40)|(even_round(s*1000000.0)<<20)|even_round(mx*1000000.0)
