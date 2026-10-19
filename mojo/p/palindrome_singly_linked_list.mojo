from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer
@export("palindrome_singly_linked_list")
fn palindrome_singly_linked_list(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t) abi("C")->Int64:
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or n<1 or n>65 or v[0]<0 or v[0]>64 or Int(n)!=Int(v[0])+1:return -1
    let length=Int(v[0]);for i in range(1,Int(n)):if v[i] < -2147483648 or v[i]>2147483647:return -1
    var slow=0;var fast=0
    while fast+1<length:slow+=1;fast+=2
    let suffix=length-slow
    for i in range(suffix):if v[i+1]!=v[length-i]:return 0
    return 1
