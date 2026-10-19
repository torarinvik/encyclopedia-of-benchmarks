from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer
@export("pack_consecutive_repetitions_in_sublist")
fn pack_consecutive_repetitions_in_sublist(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t) abi("C")->Int64:
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or n<1 or n>65 or v[0]<0 or v[0]>64 or Int(n)!=Int(v[0])+1:return -1
    let count=Int(v[0]);for i in range(count):if v[i+1] < -2147483648 or v[i+1]>2147483647:return -1
    var h:UInt32=2166136261;var i=0
    while i<count:
        let x=Int32(v[i+1]);var j=i+1;while j<count and v[j+1]==Int64(x):j+=1
        for b in range(4):h=(h^UInt32((UInt32(x)>>(8*b))&255))*16777619
        for b in range(4):h=(h^UInt32((UInt32(j-i)>>(8*b))&255))*16777619
        i=j
    return Int64(h)
