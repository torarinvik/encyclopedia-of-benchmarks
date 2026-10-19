from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin,MutAnyOrigin,UnsafePointer
@export("remove_duplicate_from_string")
fn remove_duplicate_from_string(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t,o:UnsafePointer[UInt8,MutAnyOrigin],cap:c_size_t) abi("C")->Int64:
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or n<1 or n>514 or v[0]<0 or v[0]>512 or Int(n)!=Int(v[0])+1:return -1
    var seen=InlineArray[Bool,128](fill=False);var result=InlineArray[UInt8,512](fill=0);var count=0
    for i in range(Int(v[0])):
        let x=v[i+1];if x<0 or x>127:return -1
        if not seen[Int(x)]:seen[Int(x)]=True;result[count]=UInt8(x);count+=1
    if cap<c_size_t(count) or (count>0 and o==UnsafePointer[UInt8,MutAnyOrigin]()):return -2
    for i in range(count):o[i]=result[i]
    return Int64(count)
