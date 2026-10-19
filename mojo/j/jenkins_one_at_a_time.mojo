from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin,UnsafePointer
@export("jenkins_one_at_a_time")
fn jenkins_one_at_a_time(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t) abi("C")->Int64:
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or n<1 or n>65:return -1
    let count=Int(v[0]);if count<0 or count>64 or n!=c_size_t(count+1):return -1
    var h:Int64=0
    for i in range(count):
        let b=v[i+1];if b<0 or b>127:return -1
        h=(h+b)&0xffffffff;h=(h+(h<<10))&0xffffffff;h=(h^(h>>6))&0xffffffff
    h=(h+(h<<3))&0xffffffff;h=(h^(h>>11))&0xffffffff;h=(h+(h<<15))&0xffffffff
    return h
