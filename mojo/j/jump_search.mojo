from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin,UnsafePointer
fn js_sqrt(value:Int)->Int:
    var lo=1;var hi=value//2+1;var result=1
    if value<2:return value
    while lo<=hi:
        let mid=lo+(hi-lo)//2
        if mid<=value//mid:result=mid;lo=mid+1
        else:hi=mid-1
    return result
@export("jump_search")
fn jump_search(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t,target:Int64) abi("C")->Int64:
    if n==0:return -1
    var step=js_sqrt(Int(n));var start=0;var end=step if step<Int(n) else Int(n)
    while v[end-1]<target:
        if end==Int(n):return -1
        start=end;end=Int(n) if step>Int(n)-end else end+step
    for i in range(start,end):
        if v[i]==target:return Int64(i)
        if v[i]>target:return -1
    return -1
