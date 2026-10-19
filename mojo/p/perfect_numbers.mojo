from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer
@export("perfect_numbers")
fn perfect_numbers(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t) abi("C")->Int64:
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or n!=1 or v[0]<0 or v[0]>1000000000:return -1
    let x=v[0];if x<=1:return 0
    var sum:Int64=1;var d:Int64=2
    while d<=x/d:if x%d==0:sum+=d;if d!=x/d:sum+=x/d;d+=1
    return 1 if sum==x else 0
