from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer
@export("pascals_triangle")
fn pascals_triangle(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t) abi("C")->Int64:
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or n!=1 or v[0]<1 or v[0]>31:return -1
    let rows=Int(v[0]);var a=InlineArray[Int64,31](fill=0);a[0]=1
    for r in range(1,rows):a[r]=1;for j in range(r-1,0,-1):a[j]+=a[j-1]
    var h:Int64=0
    for i in range(rows):h=(h*31+a[i])%1000000007
    return h
