from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer
@export("substring_search")
fn substring_search(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t) abi("C")->Int64:
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or n<2 or n>195:return -2
    let tl=v[0];let pl=v[1]
    if tl<0 or tl>128 or pl<0 or pl>64 or n!=c_size_t(2+tl+pl):return -2
    let ps=2+Int(tl)
    for i in range(2,Int(n)):if v[i]<1 or v[i]>127:return -2
    var ti=0;var pi=0;var start:Int64= -1
    while ti<Int(tl):
        let expected=if pi<Int(pl) then v[ps+pi] else 0
        if v[2+ti]==expected:
            if start== -1:start=ti
            pi+=1
            if pi==Int(pl):return start
            ti+=1
        else:start= -1;pi=0;ti+=1
    return -1
