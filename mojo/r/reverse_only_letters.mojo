from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin,MutAnyOrigin,UnsafePointer
fn islet(x:Int)->Bool:return (x>=65 and x<=90) or (x>=97 and x<=122)
@export("reverse_only_letters")
fn reverse_only_letters(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t,o:UnsafePointer[UInt8,MutAnyOrigin],cap:c_size_t) abi("C")->Int64:
    if n>4096 or (n>0 and v==UnsafePointer[Int64,ImmutAnyOrigin]()):return -1
    for i in range(Int(n)):if v[i]<32 or v[i]>126:return -1
    if cap<n or (n>0 and o==UnsafePointer[UInt8,MutAnyOrigin]()):return -2
    var left=0;var right=Int(n)
    for i in range(Int(n)):o[i]=UInt8(v[i])
    while left<right:
        if not islet(Int(o[left])):left+=1
        elif not islet(Int(o[right-1])):right-=1
        else:let t=o[left];o[left]=o[right-1];o[right-1]=t;left+=1;right-=1
    return Int64(n)
