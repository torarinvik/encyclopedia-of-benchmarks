from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin,MutAnyOrigin,UnsafePointer
from std.collections import List
@export("digit_separation")
fn digit_separation(input:UnsafePointer[Int64,ImmutAnyOrigin],length:c_size_t,out:UnsafePointer[UInt8,MutAnyOrigin],capacity:c_size_t) abi("C")->Int64:
    if input==UnsafePointer[Int64,ImmutAnyOrigin]() or length!=2 or (input[1]!=0 and input[1]!=1):return -1
    var value=input[0];var digits=List[Int](capacity=20)
    if value==0:digits.append(0)
    while value!=0:
        let rem=value%10;digits.append(Int(rem if rem>=0 else -rem));value/=10
    if out==UnsafePointer[UInt8,MutAnyOrigin]() or capacity<c_size_t(len(digits)):return -2
    for i in range(len(digits)):
        let src=i if input[1]==0 else len(digits)-1-i
        out[i]=UInt8(digits[src])
    return Int64(len(digits))
