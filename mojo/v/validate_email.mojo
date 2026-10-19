from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer
fn ascii_space(c:Int64)->Bool:return c==9 or c==10 or c==11 or c==12 or c==13 or c==32
@export("validate_email")
fn validate_email(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t) abi("C")->Int64:
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or n<2 or n>1025:return -1
    let len=v[0]
    if len<1 or len>1024 or n!=c_size_t(len+1):return -1
    for i in range(Int(len)):if v[i+1]<0 or v[i+1]>127:return -1
    var at= -1
    for i in range(Int(len)):
        let c=v[i+1]
        if ascii_space(c):return 0
        if c==64:
            if at>=0:return 0
            at=i
    if at<=0 or at>=Int(len)-1:return 0
    for i in range(at+2,Int(len)-1):if v[i+1]==46:return 1
    return 0
