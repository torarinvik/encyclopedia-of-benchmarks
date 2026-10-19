from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer
@export("string_to_integer")
fn string_to_integer(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t) abi("C")->Int64:
    if n>4096 or (n>0 and v==UnsafePointer[Int64,ImmutAnyOrigin]()):return -2
    for i in range(Int(n)):if v[i]<1 or v[i]>127:return -2
    var i=0
    while i<Int(n) and v[i]==32:i+=1
    var neg=False
    if i<Int(n) and (v[i]==43 or v[i]==45):neg=v[i]==45;i+=1
    let limit:Int64=if neg then 2147483648 else 2147483647;var mag:Int64=0
    while i<Int(n):
        let c=v[i]
        if c<48 or c>57:break
        let d=c-48
        if mag>limit/10 or (mag==limit/10 and d>limit%10):return if neg then -2147483648 else 2147483647
        mag=mag*10+d;i+=1
    return -mag if neg else mag
