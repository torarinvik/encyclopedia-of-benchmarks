from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin,MutAnyOrigin,UnsafePointer
from std.math import isfinite
@export("lu_pivot_decomposition")
fn lu_pivot_decomposition(v:UnsafePointer[Float64,ImmutAnyOrigin],n:c_size_t,o:UnsafePointer[Float64,MutAnyOrigin],cap:c_size_t) abi("C")->Int64:
    if v==UnsafePointer[Float64,ImmutAnyOrigin]() or n<1 or n>18:return -1
    let dv=v[0]
    if not isfinite(dv) or dv<1 or dv>4 or Float64(Int(dv))!=dv:return -1
    let d=Int(dv);let m=d*d
    if n!=c_size_t(1+m):return -1
    var a=InlineArray[Float64,16](fill=0.0);var pivot=InlineArray[Int64,5](fill=0)
    for i in range(m):
        let x=v[i+1]
        if not isfinite(x) or x < -8 or x>8 or Float64(Int(x))!=x:return -1
        a[i]=x
    for i in range(d+1):pivot[i]=Int64(i)
    for col in range(d):
        var maxv:Float64=0.0;var maxi=col
        for row in range(col,d):
            let x=a[row*d+col];let magnitude=if x<0:-x else:x
            if magnitude>maxv:maxv=magnitude;maxi=row
        if maxi!=col:
            for j in range(d):let tmp=a[col*d+j];a[col*d+j]=a[maxi*d+j];a[maxi*d+j]=tmp
            let tmp=pivot[col];pivot[col]=pivot[maxi];pivot[maxi]=tmp;pivot[d]+=1
        let pv=a[col*d+col]
        if not isfinite(pv) or pv==0:return -1
        for row in range(col+1,d):
            let mult=a[row*d+col]/pv
            if not isfinite(mult):return -1
            a[row*d+col]=mult
            for j in range(col+1,d):
                a[row*d+j]=a[row*d+j]-mult*a[col*d+j]
                if not isfinite(a[row*d+j]):return -1
    var staged=InlineArray[Float64,21](fill=0.0)
    for i in range(m):if not isfinite(a[i]):return -1
    for i in range(m):staged[i]=a[i]
    for i in range(d+1):staged[m+i]=Float64(pivot[i])
    let length=m+d+1
    if o==UnsafePointer[Float64,MutAnyOrigin]() or cap<c_size_t(length):return -2
    for i in range(length):o[i]=staged[i]
    return Int64(length)
