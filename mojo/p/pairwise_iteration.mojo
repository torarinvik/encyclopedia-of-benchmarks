from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
fn pw_put(o:UnsafePointer[UInt8,MutAnyOrigin],mut p:Int,x:Int64):
    let u=UInt64(x)
    for b in range(8):o[p]=UInt8((u>>(8*b))&255);p+=1
@export("pairwise_iteration")
fn pairwise_iteration(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t,o:UnsafePointer[UInt8,MutAnyOrigin],cap:c_size_t) abi("C")->Int64:
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or n<1 or n>129 or v[0]<0 or v[0]>128 or Int(n)!=1+Int(v[0]):return -1
    let count=Int(v[0]);for i in range(count):if v[i+1] < -1000000 or v[i+1]>1000000:return -1
    let bytes=if count>0:(count-1)*16 else:0
    if cap<c_size_t(bytes) or (bytes>0 and o==UnsafePointer[UInt8,MutAnyOrigin]()):return -2
    var p=0
    for i in range(count-1):for j in range(i,i+2):pw_put(o,mut p,v[j+1])
    return Int64(bytes)
