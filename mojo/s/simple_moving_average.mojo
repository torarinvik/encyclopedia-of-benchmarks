from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
@export("simple_moving_average")
fn simple_moving_average(a:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t,o:UnsafePointer[UInt8,MutAnyOrigin],cap:c_size_t) abi("C")->Int64:
    if a==UnsafePointer[Int64,ImmutAnyOrigin]() or n<3 or n>258:return -1
    let w=a[0];let count=a[1];if w<1 or w>256 or count<1 or count>256 or n!=c_size_t(count+2):return -1
    for i in range(Int(count)):if a[i+2]< -2147483648 or a[i+2]>2147483647:return -1
    let bytes=Int(count)*8;if o==UnsafePointer[UInt8,MutAnyOrigin]() or cap<c_size_t(bytes):return -2
    for i in range(Int(count)):
        var bits:UInt64=0x7ff8000000000000
        if i+1>=Int(w):
            var sum:Int64=0;for j in range(i+1-Int(w),i+1):sum+=a[j+2]
            bits=bitcast[UInt64](Float64(sum)/Float64(w))
        for b in range(8):o[i*8+b]=UInt8((bits>>UInt(8*b))&255)
    return Int64(bytes)
