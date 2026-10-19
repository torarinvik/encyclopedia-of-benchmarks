from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

@export("iterative_ternary_search")
fn iterative_ternary_search(input:UnsafePointer[Int64,ImmutAnyOrigin],length:c_size_t) abi("C")->Int64:
    if length<2:return -1
    let target=input[0];let n=Int(length)-1;let array=input+1
    if n==1:return 0 if array[0]==target else -1
    var left=0;var right=n-1
    while right>left:
        if array[left]==target:return Int64(left)
        if array[right]==target:return Int64(right)
        let lt=left+(right-left)//3+1;let rt=right-(right-left)//3-1
        if array[lt]<=target:left=lt
        else:right=rt
    return -1
