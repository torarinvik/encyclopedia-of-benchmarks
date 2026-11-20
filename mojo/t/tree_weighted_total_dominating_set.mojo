# Uncompiled weighted total-domination tree draft.
from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer
fn twt_min(a:Int64,b:Int64)->Int64:
    return a if a<b else b
fn twt_add(a:Int64,b:Int64)->Int64:
    return twt_min(1000000000000,a+b)
@export("tree_weighted_total_dominating_set")
fn tree_weighted_total_dominating_set(input:UnsafePointer[Int64,ImmutAnyOrigin],length:c_size_t) abi("C")->Int64:
    if input==UnsafePointer[Int64,ImmutAnyOrigin]() or length<2 or length>129: return -1
    let nv=input[0]
    if nv<1 or nv>64 or length!=c_size_t(2*nv): return -1
    let n=Int(nv)
    for v in range(1,n):
        if input[v]<0 or input[v]>=Int64(v): return -1
    let inf:Int64=1000000000000
    var weights=InlineArray[Int64,64](fill=0)
    var none=InlineArray[Int64,128](fill=0)
    var some=InlineArray[Int64,128](fill=inf)
    for v in range(n):
        weights[v]=input[n+v]
        if weights[v]<0 or weights[v]>1000000: return -1
    var root=inf
    var v=n-1
    while v>=0:
        var dp=InlineArray[Int64,4](fill=0)
        for chosen in range(2):
            let own=weights[v] if chosen==1 else 0
            dp[2*chosen]=twt_add(own,some[2*v+chosen])
            dp[2*chosen+1]=twt_add(own,twt_min(none[2*v+chosen],some[2*v+chosen]))
        if v==0:
            root=twt_min(dp[0],dp[2])
            break
        let p=Int(input[v])
        for chosen in range(2):
            let a=dp[chosen]
            let b=dp[2+chosen]
            let index=2*p+chosen
            let next=twt_min(twt_add(some[index],twt_min(a,b)),twt_add(none[index],b))
            none[index]=twt_add(none[index],a)
            some[index]=next
        v-=1
    return -2 if root==inf else root
