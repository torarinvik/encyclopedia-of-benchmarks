# Uncompiled weighted independent tree domination draft.
from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer
fn twid_min(a:Int64,b:Int64)->Int64:
    return a if a<b else b
fn twid_add(a:Int64,b:Int64)->Int64:
    return twid_min(1000000000000,a+b)
@export("tree_weighted_independent_dominating_set")
fn tree_weighted_independent_dominating_set(input:UnsafePointer[Int64,ImmutAnyOrigin],length:c_size_t) abi("C")->Int64:
    if input==UnsafePointer[Int64,ImmutAnyOrigin]() or length<2 or length>129: return -1
    let nv=input[0]
    if nv<1 or nv>64 or length!=c_size_t(2*nv): return -1
    let n=Int(nv)
    for v in range(1,n):
        if input[v]<0 or input[v]>=Int64(v): return -1
    var selected=InlineArray[Int64,64](fill=0)
    var covered=InlineArray[Int64,64](fill=1000000000000)
    var waiting=InlineArray[Int64,64](fill=0)
    for v in range(n):
        let weight=input[n+v]
        if weight<0 or weight>1000000: return -1
        selected[v]=weight
    var v=n-1
    while v>0:
        let p=Int(input[v])
        let a=selected[v]
        let b=covered[v]
        let c=waiting[v]
        let next=twid_min(twid_add(covered[p],twid_min(a,b)),twid_add(waiting[p],a))
        selected[p]=twid_add(selected[p],twid_min(b,c))
        waiting[p]=twid_add(waiting[p],b)
        covered[p]=next
        v-=1
    return twid_min(selected[0],covered[0])
