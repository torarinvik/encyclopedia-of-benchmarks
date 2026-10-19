from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer
@export("subset_count")
fn subset_count(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t) abi("C")->Int64:
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or n<2 or n>33:return -1
    let cv=v[0];let tv=v[1]
    if cv<1 or cv>30 or tv<0 or tv>64 or n!=c_size_t(cv+2):return -1
    for i in range(Int(cv)):if v[2+i]<0 or v[2+i]>64:return -1
    let target=Int(tv);var prev=InlineArray[Int64,65](fill=0);prev[0]=1;let first=Int(v[2])
    if first<=target:prev[first]=1
    for i in range(1,Int(cv)):
        let value=Int(v[2+i]);var cur=InlineArray[Int64,65](fill=0);cur[0]=1
        for amount in range(1,target+1):cur[amount]=prev[amount]+(prev[amount-value] if value<=amount else 0)
        prev=cur
    return prev[target]
