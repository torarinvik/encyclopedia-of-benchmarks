from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin,UnsafePointer
@export("linked_list_cycle_entry")
fn linked_list_cycle_entry(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t) abi("C")->Int64:
    if n>100000 or (n>0 and v==UnsafePointer[Int64,ImmutAnyOrigin]()):return -2
    for i in range(Int(n)):
        if v[i]<-1 or v[i]>=Int64(n):return -2
    if n==0:return -1
    var slow:Int64=0;var fast:Int64=0;var meeting=False
    while fast>=0:
        let first=v[Int(fast)]
        if first<0:break
        slow=v[Int(slow)];fast=v[Int(first)]
        if slow==fast:meeting=True;break
    if not meeting:return -1
    var entry:Int64=0
    while entry!=slow:entry=v[Int(entry)];slow=v[Int(slow)]
    return entry
