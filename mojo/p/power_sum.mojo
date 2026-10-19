from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer
fn ps_term(base:Int64,power:Int64)->Int64:
    var t=Int64(1)
    for _ in range(Int(power)):t*=base
    return t
fn ps_search(target:Int64,power:Int64,base:Int64,current:Int64)->Int64:
    let sum=current+ps_term(base,power)
    if sum==target:return 1
    if sum>target:return 0
    return ps_search(target,power,base+1,sum)+ps_search(target,power,base+1,current)
@export("power_sum")
fn power_sum(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t) abi("C")->Int64:
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or n!=2 or v[0]<1 or v[0]>1000 or v[1]<2 or v[1]>10:return -1
    return ps_search(v[0],v[1],1,0)
