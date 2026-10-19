from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer
fn tp_next(i:Int,n:Int,target:Int)->Int:
    if i<0:return -1
    if i==n-1:return target
    return i+1
@export("two_pointer_technique")
fn two_pointer_technique(a:UnsafePointer[Int64,ImmutAnyOrigin],len:c_size_t) abi("C")->Int64:
    if a==UnsafePointer[Int64,ImmutAnyOrigin]() or len<4 or len>132:return -1
    let op=a[0];let nv=a[1];let target=a[2];let k=a[3]
    if nv<0 or nv>128 or len!=c_size_t(nv+4) or op<0 or op>2:return -1
    if (nv==0 and target!= -1) or (nv>0 and (target< -1 or target>=nv)):return -1
    if ((op==0 or op==1) and k!=0) or (op!=0 and target!= -1):return -1
    for i in range(Int(nv)):if a[i+4]< -1000000 or a[i+4]>1000000:return -1
    if op==0:
        var slow=0;var fast=0
        while fast>=0:
            slow=tp_next(slow,Int(nv),Int(target));fast=tp_next(fast,Int(nv),Int(target))
            if fast<0:break
            fast=tp_next(fast,Int(nv),Int(target))
            if fast<0:break
            if slow==fast:return 1
        return 0
    if op==1:
        if nv==0:return -2
        var slow=0;var fast=0
        while fast>=0:
            let one=tp_next(fast,Int(nv),-1)
            if one<0:break
            slow=tp_next(slow,Int(nv),-1);fast=tp_next(one,Int(nv),-1)
        return a[slow+4]+1000001
    if k<1 or k>nv:return -1
    var lead=0
    for _ in range(Int(k)):lead=tp_next(lead,Int(nv),-1)
    var lag=0
    while lead>=0 and tp_next(lead,Int(nv),-1)>=0:lead=tp_next(lead,Int(nv),-1);lag=tp_next(lag,Int(nv),-1)
    return a[lag+4]+3000002
