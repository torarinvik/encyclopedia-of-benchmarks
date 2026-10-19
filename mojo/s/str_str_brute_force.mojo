from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer
@export("str_str_brute_force")
fn str_str_brute_force(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t) abi("C")->Int64:
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or n<2 or n>2050:return -1
    let tl=v[0];let pl=v[1]
    if tl<0 or tl>1024 or pl<0 or pl>1024 or n!=c_size_t(2+tl+pl):return -1
    for i in range(2,Int(n)):if v[i]<1 or v[i]>127:return -1
    if pl==0:return 0
    if pl>tl:return -1
    let ps=2+Int(tl)
    for start in range(Int(tl-pl)+1):
        var j=0
        while j<Int(pl) and v[2+start+j]==v[ps+j]:j+=1
        if j==Int(pl):return Int64(start)
    return -1
