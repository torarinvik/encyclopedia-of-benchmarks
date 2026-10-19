from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer
@export("mex")
fn mex(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t) abi("C")->Int64:
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or n<1 or n>100001:return -1
    let count=v[0]
    if count<0 or count>100000 or Int(n)!=Int(count)+1:return -1
    var seen=InlineArray[Int64,100001](fill=0)
    for i in range(Int(count)):
        let x=v[i+1]
        if x < -2147483648 or x>2147483647:return -1
        if x>=0 and x<=count:seen[Int(x)]=1
    for i in range(Int(count)+1):if seen[i]==0:return Int64(i)
    return count+1
