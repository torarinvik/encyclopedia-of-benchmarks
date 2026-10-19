from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin,UnsafePointer

@export("max_non_adjacent_sum")
fn max_non_adjacent_sum(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t) abi("C")->Int64:
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or n<1 or n>100000:return -9223372036854775808
    var two:Int64=0;var one:Int64=0
    for i in range(Int(n)):
        if v[i]<0 or v[i]>10000:return -9223372036854775808
        let take=two+v[i];let current=take if take>one else one
        two=one;one=current
    return one
