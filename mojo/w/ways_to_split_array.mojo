from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer
@export("ways_to_split_array")
fn ways_to_split_array(a:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t) abi("C")->Int64:
    if a==UnsafePointer[Int64,ImmutAnyOrigin]() or n<2 or n>100000:return -1
    var total:Int64=0
    for i in range(Int(n)):
        if a[i]< -100000 or a[i]>100000:return -1
        total+=a[i]
    var left:Int64=0;var result:Int64=0
    for i in range(Int(n)-1):left+=a[i];if left>=total-left:result+=1
    return result
