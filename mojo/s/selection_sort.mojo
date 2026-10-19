from std.ffi import c_size_t
from std.memory import MutAnyOrigin, UnsafePointer
@export("selection_sort")
fn selection_sort(a:UnsafePointer[Int64,MutAnyOrigin],n:c_size_t) abi("C")->None:
    for i in range(Int(n)-1):
        var m=i
        for j in range(i+1,Int(n)):if a[j]<a[m]:m=j
        if m!=i:let t=a[i];a[i]=a[m];a[m]=t
