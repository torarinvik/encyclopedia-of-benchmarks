from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin,MutAnyOrigin,UnsafePointer
from std.collections import List
fn duval_factor_put(out:UnsafePointer[UInt8,MutAnyOrigin],offset:Int,length:Int):
    let bits=UInt32(length)
    for b in range(4):out[offset+b]=UInt8((bits>>UInt(b*8))&255)
@export("duval_algorithm")
fn duval_algorithm(values:UnsafePointer[Int64,ImmutAnyOrigin],length:c_size_t,out:UnsafePointer[UInt8,MutAnyOrigin],capacity:c_size_t) abi("C")->Int64:
    if length>4096 or (length>0 and values==UnsafePointer[Int64,ImmutAnyOrigin]()):return -1
    let n=Int(length)
    for i in range(n):if values[i]<0 or values[i]>127:return -1
    var factors=List[Int](capacity=n);var start=0
    while start<n:
        var end=start+1;var repeat=start
        while end<n and values[repeat]<=values[end]:
            if values[repeat]<values[end]:repeat=start
            else:repeat+=1
            end+=1
        let factorlen=end-repeat
        while start<=repeat:factors.append(factorlen);start+=factorlen
    let required=len(factors)*4
    if required==0:return 0
    if out==UnsafePointer[UInt8,MutAnyOrigin]() or capacity<c_size_t(required):return -2
    for i in range(len(factors)):duval_factor_put(out,i*4,factors[i])
    return Int64(len(factors))
