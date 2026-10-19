from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer
@export("naive_pattern_search")
fn naive_pattern_search(a:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t) abi("C")->Int64:
    if a==UnsafePointer[Int64,ImmutAnyOrigin]() or n<2 or n>512:return -2
    let tn=a[0];let pn=a[1]
    if tn<0 or tn>255 or pn<0 or pn>tn or pn>255 or n!=c_size_t(2+tn+pn):return -2
    for i in range(2,Int(n)):if a[i]<0 or a[i]>127:return -2
    if pn==0:return -1
    for i in range(Int(tn-pn+1)):
        var ok=True
        for j in range(Int(pn)):if a[2+i+j]!=a[2+Int(tn)+j]:ok=False;break
        if ok:return i
    return -1
