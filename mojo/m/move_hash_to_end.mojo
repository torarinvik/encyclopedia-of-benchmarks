from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
@export("move_hash_to_end")
fn move_hash_to_end(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t,o:UnsafePointer[UInt8,MutAnyOrigin],cap:c_size_t) abi("C")->Int64:
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or n<1 or n>258 or v[0]<0 or v[0]>256 or Int(n)!=1+Int(v[0]):return -1
    let count=Int(v[0]);for i in range(count):if v[i+1]<0 or v[i+1]>127:return -1
    if cap<c_size_t(count) or (count>0 and o==UnsafePointer[UInt8,MutAnyOrigin]()):return -2
    var p=0
    for i in range(count):if v[i+1]!=35:o[p]=UInt8(v[i+1]);p+=1
    while p<count:o[p]=35;p+=1
    return Int64(count)
