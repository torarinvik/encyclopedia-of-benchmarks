from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
fn knnb_store(o:UnsafePointer[UInt8,MutAnyOrigin],v:Int64):
    let u=bitcast[UInt64](v)
    for b in range(8):o[b]=UInt8((u>>UInt(8*b))&255)
@export("k_nearest_neighbors_binary")
fn k_nearest_neighbors_binary(a:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t,o:UnsafePointer[UInt8,MutAnyOrigin],cap:c_size_t) abi("C")->Int64:
    if a==UnsafePointer[Int64,ImmutAnyOrigin]() or n<3:return -1
    let d=a[0];let count=a[1];let k=a[2]
    if d<1 or d>8 or count<1 or count>128 or k<1 or k>count or k%2==0 or n!=c_size_t(3+d+count*(d+1)):return -1
    let qoff=3;let train=qoff+Int(d);var ds=InlineArray[Int64,128](fill=0);var labs=InlineArray[Int,128](fill=0)
    for i in range(Int(count)):
        var distance:Int64=0
        for j in range(Int(d)):
            let q=a[qoff+j];let x=a[train+i*(Int(d)+1)+j]
            if q< -1000 or q>1000 or x< -1000 or x>1000:return -1
            let diff=q-x;distance+=diff*diff
        let label=a[train+i*(Int(d)+1)+Int(d)]
        if label<0 or label>1:return -1
        ds[i]=distance;labs[i]=Int(label)
        for prev in range(i):if ds[prev]==distance:return -1
    var used=InlineArray[Bool,128](fill=false);var votes=InlineArray[Int,2](fill=0)
    for rank in range(Int(k)):
        var best=-1
        for i in range(Int(count)):if not used[i] and (best<0 or ds[i]<ds[best]):best=i
        used[best]=true;votes[labs[best]]+=1
    let answer=0 if votes[0]>votes[1] else 1
    if o==UnsafePointer[UInt8,MutAnyOrigin]() or cap<8:return -2
    knnb_store(o,Int64(answer));return 8
