from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer
@export("good_pairs")
fn good_pairs(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t) abi("C")->Int64:
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or n<1 or n>257 or v[0]<0 or v[0]>256 or n!=c_size_t(v[0]+1):return -1
    let count=Int(v[0])
    for i in range(count):if v[i+1]< -1000000 or v[i+1]>1000000:return -1
    var pairs:Int64=0
    for i in range(count):
        for j in range(i+1,count):if v[i+1]==v[j+1]:pairs+=1
    return pairs
