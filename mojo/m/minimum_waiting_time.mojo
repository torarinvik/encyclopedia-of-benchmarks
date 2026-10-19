from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer
@export("minimum_waiting_time")
fn minimum_waiting_time(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t) abi("C")->Int64:
    if n>64 or (n>0 and v==UnsafePointer[Int64,ImmutAnyOrigin]()):return -9223372036854775808
    var a=InlineArray[Int64,64](fill=0)
    for i in range(Int(n)):
        if v[i]<0 or v[i]>1000:return -9223372036854775808
        a[i]=v[i]
    for i in range(1,Int(n)):
        let x=a[i];var j=i
        while j>0 and a[j-1]>x:a[j]=a[j-1];j-=1
        a[j]=x
    var sum:Int64=0
    for i in range(Int(n)):sum+=a[i]*Int64(Int(n)-i-1)
    return sum
