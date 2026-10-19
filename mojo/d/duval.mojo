from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin,UnsafePointer
@export("duval")
fn duval(values:UnsafePointer[Int64,ImmutAnyOrigin],length:c_size_t) abi("C")->Int64:
    if length>4096 or (length>0 and values==UnsafePointer[Int64,ImmutAnyOrigin]()):return -1
    let n=Int(length)
    if n==0:return 0
    for i in range(n):if values[i]<0 or values[i]>127:return -1
    var i=0;var answer=0
    while i<n:
        answer=i;var j=i+1;var k=i
        while j<2*n and values[j%n]>=values[k%n]:
            if values[k%n]<values[j%n]:k=i
            else:k+=1
            j+=1
        while i<=k:i+=j-k
    return Int64(answer)
