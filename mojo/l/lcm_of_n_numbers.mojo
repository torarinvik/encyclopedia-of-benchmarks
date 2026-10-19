from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin,UnsafePointer

@export("lcm_of_n_numbers")
fn lcm_of_n_numbers(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t) abi("C")->Int64:
    if n>0 and v==UnsafePointer[Int64,ImmutAnyOrigin]():return -1
    for i in range(Int(n)):
        if v[i]<0:return -1
        if v[i]==0:return 0
    var acc=UInt64(1);let limit=UInt64(9223372036854775807)
    for i in range(Int(n)):
        var a=acc;var b=UInt64(v[i])
        while b!=0:let r=a%b;a=b;b=r
        let reduced=acc/a
        if reduced>limit/UInt64(v[i]):return -1
        acc=reduced*UInt64(v[i])
    return Int64(acc)
