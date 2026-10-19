from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer
@export("my_atoi")
fn my_atoi(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t) abi("C")->Int64:
    if v==UnsafePointer[Int64,ImmutAnyOrigin]():return 0
    if n>256:return -9223372036854775808
    for i in range(Int(n)):if v[i]<0 or v[i]>127:return -9223372036854775808
    var start=0;var end=Int(n)
    while start<end and v[start]<=32:start+=1
    while end>start and v[end-1]<=32:end-=1
    if start==end:return 0
    var neg=False
    if v[start]==43 or v[start]==45:neg=v[start]==45;start+=1
    let limit=if neg:Int64(2147483648) else:Int64(2147483647);var mag:Int64=0
    while start<end and v[start]>=48 and v[start]<=57:
        let d=v[start]-48
        if mag>limit/10 or (mag==limit/10 and d>limit%10):return -2147483648 if neg else 2147483647
        mag=mag*10+d;start+=1
    return -mag if neg else mag
