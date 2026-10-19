from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
from std.math import sqrt, isfinite
@export("travelling_salesman_dynamic_programming")
fn travelling_salesman_python_held_karp(a:UnsafePointer[Float64,ImmutAnyOrigin],n:c_size_t,o:UnsafePointer[Float64,MutAnyOrigin],cap:c_size_t) abi("C")->Int64:
    if a==UnsafePointer[Float64,ImmutAnyOrigin]() or n<5 or n>17:return -1
    for i in range(Int(n)):
        if not isfinite(a[i]):return -1
    let nv=a[0]
    if nv<2.0 or nv>8.0 or Float64(Int64(nv))!=nv or n!=c_size_t(1+2*nv):return -1
    let count=Int(nv);var x=InlineArray[Float64,8]();var y=InlineArray[Float64,8]()
    for i in range(count):
        x[i]=a[1+2*i];y[i]=a[2+2*i]
        if x[i]< -16.0 or x[i]>16.0 or y[i]< -16.0 or y[i]>16.0 or Float64(Int64(x[i]))!=x[i] or Float64(Int64(y[i]))!=y[i]:return -1
    var dist=InlineArray[Float64,64]()
    for i in range(count):
        for j in range(count):
            let dx=x[j]-x[i];let dy=y[j]-y[i];dist[i*8+j]=sqrt(dx*dx+dy*dy)
    var dp=InlineArray[Float64,2048](1.0e300);dp[8]=0.0
    let masks=1<<count
    for mask in range(masks):
        for u in range(count):
            if (mask&(1<<u))!=0:
                let prefix=dp[mask*8+u]
                for v in range(count):
                    let bit=1<<v
                    if (mask&bit)==0:
                        let next=mask|bit;let candidate=prefix+dist[u*8+v]
                        if candidate<dp[next*8+v]:dp[next*8+v]=candidate
    let final=masks-1;var minimum:Float64=1.0e300;var end=count
    for u in range(1,count):
        let cand=dp[final*8+u]+dist[u*8]
        if minimum>cand:minimum=cand;end=u
    if end==count:return -1
    var reverse=InlineArray[Int,9]();var plen=0;var mask=final
    while end!=0:
        reverse[plen]=end;plen+=1;let prev=mask^(1<<end);var found=False
        for u in range(count):
            if (mask&(1<<u))!=0 and dp[mask*8+end]==dp[prev*8+u]+dist[u*8+end]:mask=prev;end=u;found=True;break
        if not found or plen>8:return -1
    reverse[plen]=0;plen+=1
    for i in range(plen/2):let t=reverse[i];reverse[i]=reverse[plen-1-i];reverse[plen-1-i]=t
    reverse[plen]=0;plen+=1
    let outn=plen+2
    if o==UnsafePointer[Float64,MutAnyOrigin]() or cap<c_size_t(outn):return -2
    o[0]=Float64(plen)
    for i in range(plen):o[i+1]=Float64(reverse[i])
    o[plen+1]=minimum;return Int64(outn)
