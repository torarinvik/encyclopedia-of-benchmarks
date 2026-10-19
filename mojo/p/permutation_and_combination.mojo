from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer
@export("permutation_and_combination")
fn permutation_and_combination(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t) abi("C")->Int64:
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or n!=3:return -1
    let op=Int(v[0]);let a=v[1];var r=v[2];if op<0 or op>2 or a<0 or a>18:return -1
    if op==0:r=0 elif r<0 or r>a:return -1
    var result:Int64=1
    if op==0:for i in range(2,Int(a)+1):result*=Int64(i)
    elif op==1:for i in range(Int(a-r+1),Int(a)+1):result*=Int64(i)
    else:
        if r>a-r:r=a-r
        for i in range(1,Int(r)+1):result=result*(a-r+Int64(i))/Int64(i)
    return result
