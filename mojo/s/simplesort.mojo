from std.ffi import c_size_t
from std.memory import MutAnyOrigin, UnsafePointer
@export("simplesort")
fn simplesort(a:UnsafePointer[Int64,MutAnyOrigin],n:c_size_t) abi("C")->Int64:
    if n>256 or (n>0 and a==UnsafePointer[Int64,MutAnyOrigin]()):return -1
    for i in range(Int(n)):if a[i]< -1000000 or a[i]>1000000:return -1
    for i in range(Int(n)-1):for j in range(i+1,Int(n)):if a[j]<a[i]:let t=a[i];a[i]=a[j];a[j]=t
    var sum:Int64=0;for i in range(Int(n)):sum+=(i+1)*(a[i]+1000001)
    return sum
