from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer
@export("number_of_local_maximum_points")
fn number_of_local_maximum_points(a:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t) abi("C")->Int64:
    if a==UnsafePointer[Int64,ImmutAnyOrigin]() or n<1 or n>4096:return -1
    for i in range(Int(n)):if a[i]< -2147483648 or a[i]>2147483647:return -1
    if n==1:return 0
    var count:Int64=0
    for i in range(Int(n)):
        if i==0:
            if a[i]>a[i+1]:count+=1
        elif i==Int(n)-1:
            if a[i]>a[i-1]:count+=1
        elif a[i]>a[i-1] and a[i]>a[i+1]:count+=1
    return count
