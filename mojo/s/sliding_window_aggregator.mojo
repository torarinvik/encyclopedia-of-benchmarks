from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer
@export("sliding_window_aggregator")
fn sliding_window_aggregator(a:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t) abi("C")->Int64:
    if a==UnsafePointer[Int64,ImmutAnyOrigin]() or n<3 or n>259:return -9223372036854775808
    let cap=a[0];let count=a[1];if cap<1 or cap>64 or count<1 or count>256 or n!=c_size_t(count+2):return -9223372036854775808
    var total:Int64=0;let start=Int(count-cap) if count>cap else 0
    for i in range(start,Int(count)):
        let v=a[i+2];if v< -1000000 or v>1000000:return -9223372036854775808
        total+=v
    for i in range(0,start):if a[i+2]< -1000000 or a[i+2]>1000000:return -9223372036854775808
    return total
