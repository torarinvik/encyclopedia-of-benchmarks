from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
from std.collections import InlineArray

fn iom_store(out:UnsafePointer[UInt8,MutAnyOrigin],offset:Int,x:Float64):
    let bits=bitcast[UInt64](x)
    for b in range(8):out[offset+b]=UInt8((bits>>(8*b))&255)

@export("inverse_of_matrix")
fn inverse_of_matrix(input:UnsafePointer[Int64,ImmutAnyOrigin],length:c_size_t,
                     output:UnsafePointer[UInt8,MutAnyOrigin],capacity:c_size_t) abi("C")->Int64:
    if input==UnsafePointer[Int64,ImmutAnyOrigin]() or length<1 or length>11:return -1
    let nv=input[0]
    if (nv!=2 and nv!=3) or length!=c_size_t(1+nv*nv):return -1
    let n=Int(nv)
    var q=InlineArray[Int64,9](fill=0);var a=InlineArray[Float64,9](fill=0.0)
    for i in range(n*n):
        let v=input[i+1]
        if v< -32 or v>32:return -1
        q[i]=v;a[i]=Float64(v)/16.0
    var dom=InlineArray[Int32,3](fill=-1);var seen=InlineArray[Bool,3](fill=False)
    for r in range(n):
        for c in range(n):
            var others:Int64=0
            for j in range(n):
                if j!=c:others+=abs(q[r*n+j])
            if abs(q[r*n+c])>others:
                if dom[r]!= -1:return -1
                dom[r]=Int32(c)
        if dom[r]== -1 or seen[Int(dom[r])]:return -1
        seen[Int(dom[r])]=True
    var b=InlineArray[Float64,9](fill=0.0);var scale=InlineArray[Float64,3](fill=0.0);var idx=InlineArray[Int32,3](fill=0)
    for r in range(n):
        idx[r]=Int32(r)
        for c in range(n):
            if r==c:b[r*n+c]=1.0
            if abs(a[r*n+c])>scale[r]:scale[r]=abs(a[r*n+c])
        if scale[r]==0.0:return -1
    for c in range(n-1):
        var best_ratio=0.0;var best=c
        for r in range(c,n):
            let ratio=abs(a[Int(idx[r])*n+c])/scale[Int(idx[r])]
            if ratio>best_ratio:best_ratio=ratio;best=r
        let t=idx[c];idx[c]=idx[best];idx[best]=t
        let pivotrow=Int(idx[c]);let pivot=a[pivotrow*n+c]
        if pivot==0.0:return -1
        for r in range(c+1,n):
            let cr=Int(idx[r]);let factor=a[cr*n+c]/pivot;a[cr*n+c]=factor
            for trail in range(c+1,n):a[cr*n+trail]=a[cr*n+trail]-factor*a[pivotrow*n+trail]
    for r in range(n-1):
        let cr=Int(idx[r])
        for lower in range(r+1,n):
            let lr=Int(idx[lower])
            for c in range(n):b[lr*n+c]=b[lr*n+c]-a[lr*n+r]*b[cr*n+c]
    var inverse=InlineArray[Float64,9](fill=0.0)
    for c in range(n):
        let last=Int(idx[n-1]);let pivot=a[last*n+n-1]
        if pivot==0.0:return -1
        inverse[(n-1)*n+c]=b[last*n+c]/pivot
        var step=n-2
        while step>=0:
            let row=Int(idx[step]);var value=b[row*n+c]
            for trail in range(step+1,n):value-=a[row*n+trail]*inverse[trail*n+c]
            let p=a[row*n+step]
            if p==0.0:return -1
            inverse[step*n+c]=value/p;step-=1
    if output==UnsafePointer[UInt8,MutAnyOrigin]() or capacity<c_size_t(n*n*8):return -2
    for i in range(n*n):iom_store(output,i*8,inverse[i])
    return Int64(n*n*8)
