from std.ffi import c_size_t
from std.math import exp, sqrt
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
comptime MAXN=8
comptime MAXD=4
comptime MAXQ=16
fn svc_kernel(a:UnsafePointer[Float64,MutAnyOrigin],b:UnsafePointer[Float64,MutAnyOrigin],ai:Int,bi:Int,d:Int,kind:Int64)->Float64:
    if kind==0:
        var total=0.0
        for k in range(d):total+=a[ai+k]*b[bi+k]
        return total
    var norm=0.0
    for k in range(d):let diff=a[ai+k]-b[bi+k];norm+=diff*diff
    return exp(-norm)
@export("support_vector_classifier")
fn support_vector_classifier(v:UnsafePointer[Int64,ImmutAnyOrigin],nlen:c_size_t) abi("C")->Int64:
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or nlen<4 or nlen>109:return -1
    let n64=v[0];let d64=v[1];let kind=v[2];let q64=v[3]
    if n64<2 or n64>8 or d64<1 or d64>4 or kind<0 or kind>1 or q64<1 or q64>16:return -1
    let n=Int(n64);let d=Int(d64);let q=Int(q64)
    if nlen!=c_size_t(4+n+n*d+q*d):return -1
    var labels=InlineArray[Float64,MAXN](fill=0);var neg=False;var pos=False
    for i in range(n):
        if v[4+i]!= -1 and v[4+i]!=1:return -1
        labels[i]=Float64(v[4+i]);if v[4+i]<0:neg=True
        else:pos=True
    if not neg or not pos:return -1
    var train=InlineArray[Float64,MAXN*MAXD](fill=0);var test=InlineArray[Float64,MAXQ*MAXD](fill=0)
    let ts=4+n
    for i in range(n):
        for j in range(d):
            let x=v[ts+i*d+j]
            if x< -4 or x>4:return -1
            train[i*MAXD+j]=Float64(x)
    let qs=ts+n*d
    for i in range(q):
        for j in range(d):
            let x=v[qs+i*d+j]
            if x< -4 or x>4:return -1
            test[i*MAXD+j]=Float64(x)
    var km=InlineArray[Float64,MAXN*MAXN](fill=0)
    for i in range(n):
        for j in range(n):km[i*MAXN+j]=svc_kernel(train.unsafe_ptr(),train.unsafe_ptr(),i*MAXD,j*MAXD,d,kind)
    var optimum=InlineArray[Float64,MAXN](fill=0.5)
    for iteration in range(5000):
        var grad=InlineArray[Float64,MAXN](fill=0);var old=InlineArray[Float64,MAXN](fill=0)
        for i in range(n):
            var total=0.0
            for j in range(n):total+=optimum[j]*labels[j]*km[i*MAXN+j]
            grad[i]=labels[i]*total-1.0;old[i]=optimum[i]
        let lr=0.1/(1.0+Float64(iteration)/1000.0)
        for i in range(n):
            let updated=optimum[i]-lr*grad[i]
            optimum[i]=0.0 if updated<0.0 else (1.0 if updated>1.0 else updated)
        var sum=0.0
        for i in range(n):sum+=optimum[i]*labels[i]
        var correction=sum/Float64(n)
        for _ in range(10):
            for i in range(n):
                let updated=optimum[i]-correction*labels[i]
                optimum[i]=0.0 if updated<0.0 else (1.0 if updated>1.0 else updated)
            sum=0.0
            for i in range(n):sum+=optimum[i]*labels[i]
            correction=sum/Float64(n)
            if abs(sum)<1e-10:break
        var diff2=0.0
        for i in range(n):let delta=optimum[i]-old[i];diff2+=delta*delta
        if sqrt(diff2)<1e-8:break
    var offset=0.0;var offset_count=0
    for i in range(n):
        if optimum[i]>1e-5 and optimum[i]<1.0-1e-5:
            var total=0.0
            for j in range(n):total+=optimum[j]*labels[j]*svc_kernel(train.unsafe_ptr(),train.unsafe_ptr(),j*MAXD,i*MAXD,d,kind)
            offset+=labels[i]-total;offset_count+=1
    if offset_count==0:
        for i in range(n):
            var total=0.0
            for j in range(n):total+=optimum[j]*labels[j]*svc_kernel(train.unsafe_ptr(),train.unsafe_ptr(),j*MAXD,i*MAXD,d,kind)
            offset+=labels[i]-total
        offset/=Float64(n)
    else:offset/=Float64(offset_count)
    var mask:Int64=0
    for i in range(q):
        var total=0.0
        for j in range(n):total+=optimum[j]*labels[j]*svc_kernel(train.unsafe_ptr(),test.unsafe_ptr(),j*MAXD,i*MAXD,d,kind)
        if total+offset>=0.0:mask|=Int64(1)<<UInt(i)
    return mask
