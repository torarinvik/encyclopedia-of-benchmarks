from std.ffi import c_size_t
from std.memory import MutAnyOrigin, UnsafePointer
@export("sentinel_search")
fn sentinel_search(a:UnsafePointer[Int64,MutAnyOrigin],n:c_size_t,target:Int64) abi("C")->Int64:
    if n==0:return -1
    let last=Int(n)-1;let saved=a[last];if saved==target:return Int64(last)
    a[last]=target;var i=0
    while a[i]!=target:i+=1
    a[last]=saved
    return -1 if i==last else Int64(i)
