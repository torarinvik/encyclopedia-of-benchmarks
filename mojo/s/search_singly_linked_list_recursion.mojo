from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer
fn recursive_find(a:UnsafePointer[Int64,ImmutAnyOrigin],at:Int,count:Int,key:Int64)->Bool:
    if at>=count:return False
    if a[at+2]==key:return True
    return recursive_find(a,at+1,count,key)
@export("search_singly_linked_list_recursion")
fn search_singly_linked_list_recursion(a:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t) abi("C")->Int64:
    if a==UnsafePointer[Int64,ImmutAnyOrigin]() or n<2 or n>66:return -1
    let count=a[0];let key=a[1]
    if count<0 or count>64 or n!=c_size_t(count+2) or key< -2147483648 or key>2147483647:return -1
    for i in range(Int(count)):if a[i+2]< -2147483648 or a[i+2]>2147483647:return -1
    return 1 if recursive_find(a,0,Int(count),key) else 0
