from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer
@export("xor_search_missing_number")
fn xor_search_missing_number(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t) abi("C")->Int64:
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or n<1 or n>257:return -1
    let count=v[0]
    if count<0 or count>255 or n!=c_size_t(count+1):return -1
    var seen=InlineArray[UInt8,256](fill=0);var result=count
    for i in range(Int(count)):
        let value=v[i+1]
        if value<0 or value>count or seen[Int(value)]!=0:return -1
        seen[Int(value)]=1;result=result^Int64(i)^value
    return result
