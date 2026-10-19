from std.ffi import c_size_t
from std.memory import MutAnyOrigin, UnsafePointer
@export("shrink_shell_sort")
fn shrink_shell_sort(a:UnsafePointer[Int64,MutAnyOrigin],n:c_size_t) abi("C")->None:
    if n<2:return
    var gap=Int(n)
    while gap>1:
        gap=Int(Float64(gap)/1.3)
        for i in range(gap,Int(n)):
            let key=a[i];var j=i
            while j>=gap and a[j-gap]>key:a[j]=a[j-gap];j-=gap
            a[j]=key
