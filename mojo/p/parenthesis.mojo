from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer
@export("parenthesis")
fn parenthesis(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t) abi("C")->Int64:
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or n<1 or n>129 or v[0]<0 or v[0]>128 or Int(n)!=Int(v[0])+1:return -1
    var balance:Int64=0
    for i in range(1,Int(n)):
        if v[i]<0 or v[i]>127:return -1
        if v[i]==40:balance+=1
        elif v[i]==41:balance-=1;if balance<0:return 0
    return 1 if balance==0 else 0
