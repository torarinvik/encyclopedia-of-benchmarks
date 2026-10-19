from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer
@export("string_prefix_suffix")
fn string_prefix_suffix(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t) abi("C")->Int64:
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or n<3 or n>2052:return -1
    let mode=v[0];let tn=v[1];let pn=v[2]
    if (mode!=0 and mode!=1) or tn<0 or tn>1024 or pn<0 or pn>1024 or n!=c_size_t(3+tn+pn):return -1
    for i in range(3,Int(n)):if v[i]<0 or v[i]>65535:return -1
    if pn>tn:return 0
    let start=if mode==0 then 0 else Int(tn-pn)
    for i in range(Int(pn)):if v[3+start+i]!=v[3+Int(tn)+i]:return 0
    return 1
