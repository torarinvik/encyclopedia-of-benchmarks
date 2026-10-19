from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin,UnsafePointer
@export("LocalMaximumPoint")
fn local_maximum_point(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t) abi("C")->Int64:
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or n<1 or n>64:return -1
    for i in range(Int(n)):
        if v[i]<-1000000 or v[i]>1000000:return -1
    var s=0;var e=Int(n)-1
    while True:
        let m=s+(e-s)/2
        if (m==0 or v[m-1]<=v[m]) and (m==Int(n)-1 or v[m+1]<=v[m]):return Int64(m)
        if m>0 and v[m-1]>v[m]:e=m-1
        else:s=m+1
