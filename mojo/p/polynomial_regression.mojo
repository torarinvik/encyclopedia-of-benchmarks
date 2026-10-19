from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
from std.math import sqrt, isfinite

@export("polynomial_regression")
fn polynomial_regression(v:UnsafePointer[Float64,ImmutAnyOrigin],n:c_size_t,out:UnsafePointer[Float64,MutAnyOrigin],cap:c_size_t) abi("C")->Int64:
    if v==UnsafePointer[Float64,ImmutAnyOrigin]() or n<3 or n>18:return -1
    for i in range(Int(n)):if not isfinite(v[i]):return -1
    if v[0]<0 or v[0]>3 or v[0]!=Float64(Int(v[0])) or v[1]<1 or v[1]>5 or v[1]!=Float64(Int(v[1])) or v[2]<1 or v[2]>4 or v[2]!=Float64(Int(v[2])):return -1
    let deg=Int(v[0]);let rows=Int(v[1]);let queries=Int(v[2]);let cols=deg+1
    if rows<cols or n!=c_size_t(3+2*rows+queries):return -1
    var xs=InlineArray[Float64,5](fill=0.0);var ys=InlineArray[Float64,5](fill=0.0);var xq=InlineArray[Float64,4](fill=0.0)
    for r in range(rows):
        xs[r]=v[3+r];ys[r]=v[3+rows+r]
        if xs[r]<-2 or xs[r]>2 or xs[r]!=Float64(Int(xs[r])) or ys[r]<-32 or ys[r]>32 or ys[r]!=Float64(Int(ys[r])):return -1
        for j in range(r):if xs[j]==xs[r]:return -1
    for q in range(queries):
        xq[q]=v[3+2*rows+q]
        if xq[q]<-2 or xq[q]>2 or xq[q]!=Float64(Int(xq[q])):return -1
    var design=InlineArray[Float64,20](fill=0.0)
    for r in range(rows):
        var power=1.0
        for c in range(cols):design[r*cols+c]=power;power*=xs[r]
    var qmat=InlineArray[Float64,20](fill=0.0);var rmat=InlineArray[Float64,16](fill=0.0)
    for c in range(cols):
        var vec=InlineArray[Float64,5](fill=0.0)
        for r in range(rows):vec[r]=design[r*cols+c]
        for prev in range(c):
            var dot=0.0
            for r in range(rows):dot+=qmat[r*cols+prev]*vec[r]
            rmat[prev*cols+c]=dot
            for r in range(rows):vec[r]-=dot*qmat[r*cols+prev]
        var norm2=0.0
        for r in range(rows):norm2+=vec[r]*vec[r]
        if not isfinite(norm2) or norm2<=0:return -1
        let norm=sqrt(norm2);rmat[c*cols+c]=norm
        for r in range(rows):qmat[r*cols+c]=vec[r]/norm
    var projected=InlineArray[Float64,4](fill=0.0)
    for c in range(cols):for r in range(rows):projected[c]+=qmat[r*cols+c]*ys[r]
    var beta=InlineArray[Float64,4](fill=0.0)
    for k in range(cols):
        let c=cols-1-k;var value=projected[c]
        for next in range(c+1,cols):value-=rmat[c*cols+next]*beta[next]
        if rmat[c*cols+c]==0:return -1
        beta[c]=value/rmat[c*cols+c]
        if not isfinite(beta[c]):return -1
    var result=InlineArray[Float64,8](fill=0.0)
    for c in range(cols):result[c]=beta[c]
    for q in range(queries):
        var pred=0.0;var power=1.0
        for c in range(cols):pred+=power*beta[c];power*=xq[q]
        if not isfinite(pred):return -1
        result[cols+q]=pred
    let needed=cols+queries
    if out==UnsafePointer[Float64,MutAnyOrigin]() or cap<c_size_t(needed):return -2
    for i in range(needed):out[i]=result[i]
    return Int64(needed)
