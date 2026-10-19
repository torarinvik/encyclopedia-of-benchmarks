from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer
@export("mode")
fn mode(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t) abi("C")->Int64:
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or n<1 or n>4096:return -1
    var counts=InlineArray[Int64,256](fill=0)
    for i in range(Int(n)):
        if v[i]<0 or v[i]>255:return -1
        counts[Int(v[i])]+=1
    var best=0;var answer:Int64=-1;var unique=True
    for i in range(256):
        if counts[i]>best:best=Int(counts[i]);answer=Int64(i);unique=True
        elif counts[i]!=0 and counts[i]==best:unique=False
    return answer if unique else -1
