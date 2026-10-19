from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer
@export("two_pointer")
fn two_pointer(a:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t) abi("C")->Int64:
    if a==UnsafePointer[Int64,ImmutAnyOrigin]() or n<2 or n>258:return -2
    let count=a[0];let target=a[1]
    if count<0 or count>256 or n!=c_size_t(count+2):return -2
    var previous:Int64= -2147483649
    for i in range(Int(count)):
        let x=a[i+2]
        if x< -2147483648 or x>2147483647 or x<previous:return -2
        previous=x
    var l=0;var r=Int(count)-1
    while l<r:
        let s=a[l+2]+a[r+2]
        if s==target:return Int64(l*256+r)
        if s<target:l+=1
        else:r-=1
    return -1
