from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin,UnsafePointer
from std.collections import InlineArray

@export("median")
fn median(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t) abi("C")->Int64:
    if n==0 or n>1024:return 0
    var a=InlineArray[Int64,1024](fill=0)
    for i in range(Int(n)):a[i]=v[i]
    for i in range(1,Int(n)):
        let x=a[i];var j=i
        while j>0 and a[j-1]>x:a[j]=a[j-1];j-=1
        a[j]=x
    if n%2!=0:return a[Int(n)/2]*2
    return a[Int(n)/2-1]+a[Int(n)/2]
