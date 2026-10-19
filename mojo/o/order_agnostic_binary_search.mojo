from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin,UnsafePointer
@export("order_agnostic_binary_search")
fn order_agnostic_binary_search(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t) abi("C")->Int64:
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or n<3 or n>100001:return -1
    let target=v[0];let count=v[1]
    if target < -2147483648 or target>2147483647 or count<1 or count>99999 or n!=c_size_t(count+2):return -1
    let ascending=v[2]<v[Int(count)+1];var left:Int64=0;var right=count-1
    while left<=right:
        let mid=left+(right-left)//2;let x=v[Int(mid)+2]
        if x==target:return mid
        if ascending:
            if x<target:left=mid+1
            else:right=mid-1
        else:
            if x>target:left=mid+1
            else:right=mid-1
    return -1
