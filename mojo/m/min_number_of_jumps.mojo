from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer
@export("min_number_of_jumps")
fn min_number_of_jumps(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t) abi("C")->Int64:
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or n<1 or n>64:return -1
    for i in range(Int(n)):if v[i]<0 or v[i]>64:return -1
    var jumps=InlineArray[Int64,64](fill=1000000000000);jumps[0]=0
    for i in range(1,Int(n)):
        for j in range(i):
            if v[j]+Int64(j)>=Int64(i) and jumps[j]+1<jumps[i]:jumps[i]=jumps[j]+1
    return jumps[Int(n)-1]
