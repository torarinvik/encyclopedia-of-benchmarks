from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin,UnsafePointer
@export("local_binary_pattern")
fn local_binary_pattern(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t) abi("C")->Int64:
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or n!=9:return -1
    for i in range(9):
        if v[i]<0 or v[i]>255:return -1
    var ix=InlineArray[Int64,8](fill=0);ix[0]=2;ix[1]=5;ix[2]=1;ix[3]=8;ix[4]=7;ix[5]=6;ix[6]=3;ix[7]=0;var result:Int64=0
    for i in range(8):
        if v[ix[i]]>=v[4]:result|=Int64(1)<<i
    return result
