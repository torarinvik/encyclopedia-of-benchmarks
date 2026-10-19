from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
from std.collections import InlineArray

@export("gale_shapley")
fn gale_shapley(v: UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t,out:UnsafePointer[UInt8,MutAnyOrigin],cap:c_size_t) abi("C")->Int64:
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or n<1 or n>51:return -2
    let count=Int(v[0]); if count<0 or count>5 or n!=c_size_t(1+2*count*count):return -2
    var ranks=InlineArray[Int64,25](fill=0);var seen=InlineArray[Bool,5](fill=False)
    for p in range(count):
        for j in range(count):seen[j]=False
        for j in range(count):
            let a=v[1+p*count+j];if a<0 or a>=count or seen[Int(a)]:return -2
            seen[Int(a)]=True
    let off=1+count*count
    for a in range(count):
        for j in range(count):seen[j]=False
        for r in range(count):
            let p=v[off+a*count+r];if p<0 or p>=count or seen[Int(p)]:return -2
            seen[Int(p)]=True;ranks[a*5+Int(p)]=r
    if cap<c_size_t(count) or (count>0 and out==UnsafePointer[UInt8,MutAnyOrigin]()):return -2
    var by_a=InlineArray[Int64,5](fill= -1);var by_p=InlineArray[Int64,5](fill= -1);var next=InlineArray[Int,5](fill=0)
    while True:
        var p=0
        while p<count and by_p[p]!= -1:p+=1
        if p==count:break
        let a=Int(v[1+p*count+next[p]]);next[p]+=1
        let cur=by_a[a]
        if cur== -1 or ranks[a*5+p]<ranks[a*5+Int(cur)]:
            if cur!= -1:by_p[Int(cur)]= -1
            by_a[a]=p;by_p[p]=Int64(a)
    for p in range(count):out[p]=UInt8(by_p[p])
    return Int64(count)
