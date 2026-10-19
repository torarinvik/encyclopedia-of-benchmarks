from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer
from std.collections import InlineArray

@export("is_isomorphic")
fn is_isomorphic(input:UnsafePointer[Int64,ImmutAnyOrigin],length:c_size_t) abi("C")->Int64:
    if input==UnsafePointer[Int64,ImmutAnyOrigin]() or length<2 or length>20:return -1
    let n=input[0];let m=input[1]
    if n<0 or n>8 or m<0 or m>8 or length!=c_size_t(2+n+m):return -1
    for i in range(2,Int(length)):
        if input[i]<0 or input[i]>127:return -1
    if n!=m:return 0
    var forward=InlineArray[Int32,128](fill=-1);var reverse=InlineArray[Int32,128](fill=-1)
    for i in range(Int(n)):
        let a=Int(input[2+i]);let b=Int(input[2+Int(n)+i])
        if (forward[a]!= -1 and forward[a]!=b) or (reverse[b]!= -1 and reverse[b]!=a):return 0
        forward[a]=Int32(b);reverse[b]=Int32(a)
    return 1
