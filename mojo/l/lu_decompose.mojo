from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin,MutAnyOrigin,UnsafePointer
from std.math import isfinite
@export("lu_decompose")
fn lu_decompose(v:UnsafePointer[Float64,ImmutAnyOrigin],n:c_size_t,o:UnsafePointer[Float64,MutAnyOrigin],cap:c_size_t) abi("C")->Int64:
    if v==UnsafePointer[Float64,ImmutAnyOrigin]() or n<1 or n>18:return -1
    let dv=v[0]
    if not isfinite(dv) or dv<1 or dv>4 or Float64(Int(dv))!=dv:return -1
    let d=Int(dv);let m=d*d
    if n!=c_size_t(1+m):return -1
    var a=InlineArray[Float64,16](fill=0.0);var l=InlineArray[Float64,16](fill=0.0);var u=InlineArray[Float64,16](fill=0.0)
    for i in range(m):
        let x=v[i+1]
        if not isfinite(x) or x < -8 or x>8 or Float64(Int(x))!=x:return -1
        a[i]=x
    for row in range(d):
        for col in range(row,d):
            var sum:Float64=0.0
            for k in range(row):sum+=l[row*d+k]*u[k*d+col]
            u[row*d+col]=a[row*d+col]-sum
            if not isfinite(u[row*d+col]):return -1
        let pivot=u[row*d+row]
        if not isfinite(pivot) or pivot==0:return -1
        for col in range(row,d):
            if row==col:l[row*d+col]=1.0
            else:
                var sum:Float64=0.0
                for k in range(row):sum+=l[col*d+k]*u[k*d+row]
                let value=(a[col*d+row]-sum)/pivot
                if not isfinite(value):return -1
                l[col*d+row]=value
    var staged=InlineArray[Float64,32](fill=0.0)
    for i in range(m):
        if not isfinite(l[i]) or not isfinite(u[i]):return -1
        staged[i]=l[i];staged[m+i]=u[i]
    let length=2*m
    if o==UnsafePointer[Float64,MutAnyOrigin]() or cap<c_size_t(length):return -2
    for i in range(length):o[i]=staged[i]
    return Int64(length)
