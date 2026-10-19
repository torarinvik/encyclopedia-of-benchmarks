from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer
from std.math import sqrt
@export("kmeans_raw_r")
fn kmeans_raw_r(a:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t) abi("C")->Float64:
    if a==UnsafePointer[Int64,ImmutAnyOrigin]() or n<12 or n>144:return -1.0e300
    let rows=a[0];let dims=a[1];let k=a[2];let limit=a[3]
    if rows<2 or rows>32 or dims<2 or dims>4 or k<1 or k>8 or k>rows//2 or limit<1 or limit>64:return -1.0e300
    let data0=4+Int(k);let select0=data0+Int(rows*dims);if n!=c_size_t(select0+3):return -1.0e300
    for c in range(Int(k)):
        if a[4+c]<0 or a[4+c]>=rows:return -1.0e300
        for j in range(c):if a[4+j]==a[4+c]:return -1.0e300
    var data=InlineArray[Float64,128]();for i in range(Int(rows*dims)):
        if a[data0+i]<-64 or a[data0+i]>64:return -1.0e300
        data[i]=Float64(a[data0+i])
    let field=a[select0];let arg0=a[select0+1];let arg1=a[select0+2]
    if field<0 or field>2:return -1.0e300
    if field==0 and (arg0<0 or arg0>=k or arg1<0 or arg1>=dims):return -1.0e300
    if field==1 and (arg0<0 or arg0>=rows or arg1<0 or arg1>=k):return -1.0e300
    if field==2 and (arg0<0 or arg0>=rows or arg1!=0):return -1.0e300
    var centers=InlineArray[Float64,32]();var assignments=InlineArray[Int64,32]();var distances=InlineArray[Float64,256]()
    for c in range(Int(k)):
        let r=Int(a[4+c]);for d in range(Int(dims)):centers[c*Int(dims)+d]=data[r*Int(dims)+d]
    var stable=False
    for _ in range(Int(limit)):
        var cnt=InlineArray[Int64,8]()
        for r in range(Int(rows)):
            var best=0;var bd:Float64=0.0
            for d in range(Int(dims)):let z=data[r*Int(dims)+d]-centers[d];bd+=z*z
            distances[r*Int(k)]=sqrt(bd)
            for c in range(1,Int(k)):
                var s:Float64=0.0
                for d in range(Int(dims)):let z=data[r*Int(dims)+d]-centers[c*Int(dims)+d];s+=z*z
                distances[r*Int(k)+c]=sqrt(s)
                if distances[r*Int(k)+c]<distances[r*Int(k)+best]:best=c
            assignments[r]=best;cnt[best]+=1
        for c in range(Int(k)):if cnt[c]<2:return -1.0e300
        var upd=InlineArray[Float64,32]()
        for r in range(Int(rows)):
            let c=Int(assignments[r]);for d in range(Int(dims)):upd[c*Int(dims)+d]+=data[r*Int(dims)+d]
        stable=True
        for c in range(Int(k)):
            for d in range(Int(dims)):
                let i=c*Int(dims)+d;upd[i]/=Float64(cnt[c]);if upd[i]!=centers[i]:stable=False
        for i in range(Int(k*dims)):centers[i]=upd[i]
        if stable:break
    if not stable:return -1.0e300
    if field==0:return centers[Int(arg0*dims+arg1)]
    if field==1:return distances[Int(arg0*k+arg1)]
    return Float64(assignments[Int(arg0)])
