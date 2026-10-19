from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin,UnsafePointer
@export("linked_list_has_cycle")
fn linked_list_has_cycle(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t) abi("C")->Int64:
    if n>100000 or (n>0 and v==UnsafePointer[Int64,ImmutAnyOrigin]()):return -1
    for i in range(Int(n)):
        if v[i]<-1 or v[i]>=Int64(n):return -1
    if n==0:return 0
    var slow:Int64=0;var fast:Int64=0
    while fast>=0:
        let first=v[Int(fast)]
        if first<0:break
        slow=v[Int(slow)];fast=v[Int(first)]
        if slow==fast:return 1
    return 0
