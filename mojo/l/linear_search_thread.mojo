from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin,UnsafePointer
@export("linear_search_thread")
fn linear_search_thread(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t) abi("C")->Int64:
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or n<4 or n>69:return -1
    let count=v[0];let l=v[1];let r=v[2];let target=v[3]
    if count<1 or count>64 or n!=c_size_t(count+4) or l<0 or l>r or r>count or target < -2147483648 or target>2147483647:return -1
    for i in range(Int(count)):
        if v[4+i] < -2147483648 or v[4+i]>2147483647:return -1
    for i in range(Int(l),Int(r)):
        if v[4+i]==target:return 1
    return 0
