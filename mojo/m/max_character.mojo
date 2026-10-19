from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin,UnsafePointer
from std.collections import InlineArray

@export("max_character")
fn max_character(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t) abi("C")->Int64:
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or n==0 or n>256:return -1
    var counts=InlineArray[Int,26](fill=0)
    for i in range(Int(n)):
        if v[i]<97 or v[i]>122:return -1
        counts[Int(v[i]-97)]+=1
    var best=0;var code= -1;var tied=False
    for i in range(26):
        if counts[i]>best:best=counts[i];code=97+i;tied=False
        elif counts[i]==best and best!=0:tied=True
    return -1 if tied else Int64(code)
