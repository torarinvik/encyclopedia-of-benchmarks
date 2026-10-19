from std.ffi import c_size_t
from std.memory import MutAnyOrigin, UnsafePointer
@export("shell_sort")
fn shell_sort(a:UnsafePointer[Int64,MutAnyOrigin],n:c_size_t) abi("C")->None:
    var gap=Int(n)/2
    while gap>0:
        for i in range(gap,Int(n)):
            let key=a[i];var j=i
            while j>=gap and a[j-gap]>key:a[j]=a[j-gap];j-=gap
            a[j]=key
        gap/=2
