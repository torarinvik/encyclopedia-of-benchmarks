from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer
@export("harshad_number")
fn harshad_number(a:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t) abi("C")->Int64:
    if a==UnsafePointer[Int64,ImmutAnyOrigin]() or n!=1 or a[0]<1 or a[0]>2147483647:return -1
    var x=a[0];var sum:Int64=0
    while x>0:sum+=x%10;x/=10
    return 1 if a[0]%sum==0 else 0
