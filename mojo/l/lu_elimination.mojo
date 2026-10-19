from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin,MutAnyOrigin,UnsafePointer
from std.math import isfinite
@export("lu_elimination")
fn lu_elimination(v:UnsafePointer[Float64,ImmutAnyOrigin],n:c_size_t,o:UnsafePointer[Float64,MutAnyOrigin],cap:c_size_t) abi("C")->Int64:
    if v==UnsafePointer[Float64,ImmutAnyOrigin]() or n<1 or n>22:return -1
    let dv=v[0]
    if not isfinite(dv) or dv<0 or dv>4 or Float64(Int(dv))!=dv:return -1
    let d=Int(dv);let m=d*d
    if n!=c_size_t(1+m+d):return -1
    var a=InlineArray[Float64,16](fill=0.0);var rhs=InlineArray[Float64,4](fill=0.0);var l=InlineArray[Float64,16](fill=0.0);var u=InlineArray[Float64,16](fill=0.0)
    for i in range(m):
        let x=v[i+1]
        if not isfinite(x) or x < -1 or x>1 or Float64(Int(x))!=x:return -1
        a[i]=x
    for i in range(d):
        let x=v[1+m+i]
        if not isfinite(x) or x < -8 or x>8 or Float64(Int(x))!=x:return -1
        rhs[i]=x
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
                l[col*d+row]=(a[col*d+row]-sum)/pivot
                if not isfinite(l[col*d+row]):return -1
    var y=InlineArray[Float64,4](fill=0.0)
    for row in range(d):
        var sum:Float64=0.0
        for col in range(row):sum+=y[col]*l[row*d+col]
        y[row]=(rhs[row]-sum)/l[row*d+row]
        if not isfinite(y[row]):return -1
    var x=InlineArray[Float64,4](fill=0.0)
    for rev in range(d):
        let row=d-1-rev;var sum:Float64=0.0
        for col in range(row,d):sum+=x[col]*u[row*d+col]
        let pivot=u[row*d+row]
        if not isfinite(pivot) or pivot==0:return -1
        x[row]=(y[row]-sum)/pivot
        if not isfinite(x[row]):return -1
    if o==UnsafePointer[Float64,MutAnyOrigin]() or cap<c_size_t(d):return -2
    for i in range(d):o[i]=x[i]
    return Int64(d)
