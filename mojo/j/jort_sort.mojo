from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin,UnsafePointer
from std.collections import InlineArray
@export("jort_sort")
fn jort_sort(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t) abi("C")->Int64:
    if n==0:return 1
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or n>64:return -1
    var a=InlineArray[Int64,64](fill=0)
    for i in range(Int(n)):a[i]=v[i]
    for i in range(2,Int(n)):
        let key=a[i];var p=i
        while p>1 and a[p-1]>key:a[p]=a[p-1];p-=1
        a[p]=key
    for i in range(Int(n)):if a[i]!=v[i]:return 0
    return 1
