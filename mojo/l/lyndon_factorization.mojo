from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin,MutAnyOrigin,UnsafePointer
@export("lyndon_factorization")
fn lyndon_factorization(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t,out:UnsafePointer[UInt8,MutAnyOrigin],cap:c_size_t) abi("C")->Int64:
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or n<1 or n>257 or v[0]<0 or v[0]>256 or n!=c_size_t(v[0]+1):return -1
    let size=Int(v[0])
    for i in range(size):
        if v[i+1]<97 or v[i+1]>122:return -1
    let required=2*size
    if cap<c_size_t(required) or (required>0 and out==UnsafePointer[UInt8,MutAnyOrigin]()):return -2
    var start=0;var pos=0
    while start<size:
        var candidate=start+1;var match=start
        while candidate<size and v[match+1]<=v[candidate+1]:
            if v[match+1]<v[candidate+1]:match=start
            else:match+=1
            candidate+=1
        let flen=candidate-match
        while start<=match:
            for j in range(flen):out[pos]=UInt8(v[start+j+1]);pos+=1
            out[pos]=0;pos+=1;start+=flen
    return Int64(pos)
