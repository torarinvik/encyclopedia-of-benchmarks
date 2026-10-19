from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer
@export("sublist_search")
fn sublist_search(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t) abi("C")->Int64:
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or n<2 or n>130:return -1
    let mc=v[0];let pc=v[1]
    if mc<0 or mc>64 or pc<0 or pc>64 or n!=c_size_t(2+mc+pc):return -1
    for i in range(2,Int(n)):if v[i]<0 or v[i]>2147483647:return -1
    if mc==0 or pc==0 or pc>mc:return 0
    let ps=2+Int(mc)
    for start in range(Int(mc-pc)+1):
        var matched=0
        while matched<Int(pc) and v[2+start+matched]==v[ps+matched]:matched+=1
        if matched==Int(pc):return 1
    return 0
