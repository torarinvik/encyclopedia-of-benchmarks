from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer
@export("partition_linked_list")
fn partition_linked_list(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t) abi("C")->Int64:
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or n<2 or n>66 or v[0]<0 or v[0]>64 or Int(n)!=Int(v[0])+2 or v[1] < -2147483648 or v[1]>2147483647:return -1
    let count=Int(v[0]);var less=InlineArray[Int64,64](fill=0);var ge=InlineArray[Int64,64](fill=0);var a=0;var b=0
    for i in range(count):let x=v[i+2];if x < -2147483648 or x>2147483647:return -1;if x<v[1]:less[a]=x;a+=1 else:ge[b]=x;b+=1
    var h:Int64=0
    for i in range(a):h=(h*2000000003+less[i]+2147483648)%1000000007
    for i in range(b):h=(h*2000000003+ge[i]+2147483648)%1000000007
    return h
