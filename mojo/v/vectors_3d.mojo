from std.ffi import c_size_t
from std.math import acos, isfinite, sqrt
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
fn dot3(a:InlineArray[Float32,3],b:InlineArray[Float32,3])->Float32:
    var d=a[0]*b[0];d+=a[1]*b[1];d+=a[2]*b[2];return d
fn norm3(a:InlineArray[Float32,3])->Float32:return sqrt(dot3(a,a))
@export("vectors_3d")
fn vectors_3d(v:UnsafePointer[Float64,ImmutAnyOrigin],n:c_size_t,o:UnsafePointer[Float64,MutAnyOrigin],cap:c_size_t) abi("C")->Int64:
    if v==UnsafePointer[Float64,ImmutAnyOrigin]() or n==0 or n>64:return -1
    let opv=v[0]
    if not isfinite(opv) or opv<0 or opv>7 or opv!=Float64(Int(opv)):return -1
    let op=Int(opv);let need=if op<=3 or op==7 then 7 else 4
    if n!=need:return -1
    var a=InlineArray[Float32,3](fill=0.0);var b=InlineArray[Float32,3](fill=0.0)
    for i in range(3):
        if not isfinite(v[1+i]) or abs(v[1+i])>1e6:return -1
        a[i]=Float32(v[1+i])
    if need==7:
        for i in range(3):
            if not isfinite(v[4+i]) or abs(v[4+i])>1e6:return -1
            b[i]=Float32(v[4+i])
    var r=InlineArray[Float64,9](fill=0.0);var count=1
    if op==0 or op==1:
        count=3
        for i in range(3):r[i]=Float64(a[i]+(b[i] if op==0 else -b[i]))
    elif op==2:r[0]=Float64(dot3(a,b))
    elif op==3:
        count=3;r[0]=Float64(a[1]*b[2]-a[2]*b[1]);r[1]=Float64(-a[0]*b[2]+a[2]*b[0]);r[2]=Float64(a[0]*b[1]-a[1]*b[0])
    elif op==4:r[0]=Float64(norm3(a))
    elif op==5:
        count=3;let norm=norm3(a)
        if Float64(norm)>=1e-9 and norm!=1.0:
            for i in range(3):r[i]=Float64(a[i]/norm)
    elif op==6:
        count=9;r[0]=0;r[1]= -Float64(a[2]);r[2]=Float64(a[1]);r[3]=Float64(a[2]);r[4]=0;r[5]= -Float64(a[0]);r[6]= -Float64(a[1]);r[7]=Float64(a[0]);r[8]=0
    else:
        let na=norm3(a);let nb=norm3(b)
        if Float64(na)<1e-9 or Float64(nb)<1e-9:r[0]=acos(-1.0)
        else:r[0]=acos(Float64(dot3(a,b)/(na*nb)))
    if o==UnsafePointer[Float64,MutAnyOrigin]() or cap<c_size_t(count):return -2
    for i in range(count):o[i]=r[i]
    return Int64(count)
