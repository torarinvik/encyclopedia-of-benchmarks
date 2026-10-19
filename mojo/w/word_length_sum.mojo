from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer
@export("word_length_sum")
fn word_length_sum(a:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t) abi("C")->Int64:
    if n>4096 or (n>0 and a==UnsafePointer[Int64,ImmutAnyOrigin]()):return -1
    var result:Int64=0
    for i in range(Int(n)):
        if a[i]<0 or a[i]>255:return -1
        if a[i]!=32:result+=1
    return result
