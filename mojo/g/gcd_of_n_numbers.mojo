from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer
fn gcdn_pair(a0:Int64,b0:Int64)->Int64:
    var a=a0;var b=b0
    while b!=0:let r=a%b;a=b;b=r
    return a
@export("gcd_of_n_numbers")
fn gcd_of_n_numbers(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t) abi("C")->Int64:
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or n<1 or n>64:return -1
    for i in range(Int(n)):if v[i]<1 or v[i]>2147483647:return -1
    var result=v[0]
    for i in range(1,Int(n)):
        if result!=1:result=gcdn_pair(result,v[i])
    return result
