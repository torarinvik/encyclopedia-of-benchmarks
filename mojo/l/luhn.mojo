from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin,UnsafePointer
@export("luhn_validate")
fn luhn_validate(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t) abi("C")->Int64:
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or n<1 or n>65:return -1
    let count=v[0]
    if count<2 or count>64 or (count&1)!=0 or n!=c_size_t(count+1):return -1
    var sum:Int64=0
    for i in range(Int(count)):
        var d=v[i+1]
        if d<0 or d>9:return -1
        if (i&1)==0:d*=2;if d>9:d-=9
        sum+=d
    return if sum%10==0:1 else:0
