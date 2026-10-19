from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer
@export("validate_subsequence")
fn validate_subsequence(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t) abi("C")->Int64:
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or n<2 or n>8194:return -1
    let al=v[0];let sl=v[1]
    if al<0 or al>4096 or sl<0 or sl>4096 or n!=c_size_t(2+al+sl):return -1
    for i in range(2,Int(n)):if v[i]< -2147483648 or v[i]>2147483647:return -1
    if al==0:return 0
    if sl==0:return 1
    var ai=0;var si=0;let start=2+Int(al)
    while si<Int(sl) and ai<Int(al):
        if v[start+si]==v[2+ai]:si+=1
        ai+=1
    return 1 if si==Int(sl) else 0
