from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin,UnsafePointer
fn double_linear_rec(values:UnsafePointer[Int64,ImmutAnyOrigin],key:Int64,left:Int,right:Int)->Int64:
    if left>right:return -1
    if values[2+left]==key:return Int64(left)
    if values[2+right]==key:return Int64(right)
    return double_linear_rec(values,key,left+1,right-1)
@export("double_linear_search_recursion")
fn double_linear_search_recursion(input:UnsafePointer[Int64,ImmutAnyOrigin],length:c_size_t) abi("C")->Int64:
    if input==UnsafePointer[Int64,ImmutAnyOrigin]() or length<2 or length>1026:return -2
    let count=input[0];let key=input[1]
    if count<0 or count>1024 or key< -2147483648 or key>2147483647 or length!=c_size_t(2+count):return -2
    for i in range(Int(count)):if input[2+i]< -2147483648 or input[2+i]>2147483647:return -2
    return double_linear_rec(input,key,0,Int(count)-1)
