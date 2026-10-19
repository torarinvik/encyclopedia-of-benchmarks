from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin,MutAnyOrigin,UnsafePointer
fn wr32l(o:UnsafePointer[UInt8,MutAnyOrigin],at:Int,x:Int64):
    let b=UInt32(Int32(x));for j in range(4):o[at+j]=UInt8((b>>(j*8))&UInt32(255))
@export("remove_linked_list_elements")
fn remove_linked_list_elements(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t,o:UnsafePointer[UInt8,MutAnyOrigin],cap:c_size_t) abi("C")->Int64:
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or n<1 or n>1025:return -1
    let target=v[0];if target< -2147483648 or target>2147483647:return -1
    var count=0
    for i in range(1,Int(n)):let x=v[i];if x< -2147483648 or x>2147483647:return -1
    for i in range(1,Int(n)):if v[i]!=target:count+=1
    if cap<c_size_t(count*4) or (count>0 and o==UnsafePointer[UInt8,MutAnyOrigin]()):return -2
    var w=0
    for i in range(1,Int(n)):if v[i]!=target:wr32l(o,w*4,v[i]);w+=1
    return Int64(w)
