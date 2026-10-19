from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer
@export("two_pointers_pair_exists")
fn two_pointers_pair_exists(a:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t) abi("C")->Int64:
    if a==UnsafePointer[Int64,ImmutAnyOrigin]() or n<2 or n>258:return -1
    let target=a[0];let count=a[1]
    if target< -2000000 or target>2000000 or count<0 or count>256 or n!=c_size_t(count+2):return -1
    var prev:Int64= -1000001
    for i in range(Int(count)):
        let x=a[i+2]
        if x< -1000000 or x>1000000 or (i>0 and x<prev):return -1
        prev=x
    var l=0;var r=Int(count)-1
    while l<r:
        let s=a[l+2]+a[r+2]
        if s==target:return 1
        if s<target:l+=1
        else:r-=1
    return 0
