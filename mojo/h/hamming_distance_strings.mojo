from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

@export("hamming_distance_strings")
fn hamming_distance_strings(input:UnsafePointer[Int64,ImmutAnyOrigin],length:c_size_t) abi("C")->Int64:
    if input==UnsafePointer[Int64,ImmutAnyOrigin]() or length<2 or length>260:return -1
    let left=input[0];let right=input[1]
    if left<0 or left>128 or right<0 or right>128 or length!=c_size_t(2+left+right):return -1
    for i in range(2,Int(length)):if input[i]<0 or input[i]>255:return -1
    if left!=right:return -1
    var count:Int64=0
    for i in range(Int(left)):if input[2+i]!=input[2+Int(left)+i]:count+=1
    return count
