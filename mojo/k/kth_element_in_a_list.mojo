from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer
@export("kth_element_in_a_list")
fn kth_element_in_a_list(a:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t) abi("C")->Int64:
    if a==UnsafePointer[Int64,ImmutAnyOrigin]() or n<3 or n>18 or a[0]<1 or a[0]>16 or a[1]<1 or a[1]>a[0] or n!=c_size_t(2+a[0]):return -1
    for i in range(Int(a[0])):if a[2+i]< -10000 or a[2+i]>10000:return -1
    return a[1+Int(a[1])]
