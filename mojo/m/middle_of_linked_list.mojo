from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer
@export("middle_of_linked_list")
fn middle_of_linked_list(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t) abi("C")->Int64:
    if n>100000 or (n!=0 and v==UnsafePointer[Int64,ImmutAnyOrigin]()):return -2
    for i in range(Int(n)):
        let x=v[i]
        if x < -1 or x>=Int64(n):return -2
    if n==0:return -1
    var slow:Int64=0;var fast:Int64=0
    while fast>=0:
        let first=v[Int(fast)]
        if first<0:break
        slow=v[Int(slow)];fast=v[Int(first)]
        if slow==fast:return -2
    slow=0;fast=0
    while fast>=0:
        let first=v[Int(fast)]
        if first<0:break
        slow=v[Int(slow)];fast=v[Int(first)]
    return slow
