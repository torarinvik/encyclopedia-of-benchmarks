from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin,MutAnyOrigin,UnsafePointer
fn delete_middle_put(out:UnsafePointer[UInt8,MutAnyOrigin],offset:Int,value:Int64):
    let bits=UInt32(value)
    for b in range(4):out[offset+b]=UInt8((bits>>UInt(b*8))&255)
@export("delete_middle_node")
fn delete_middle_node(input:UnsafePointer[Int64,ImmutAnyOrigin],length:c_size_t,out:UnsafePointer[UInt8,MutAnyOrigin],capacity:c_size_t) abi("C")->Int64:
    if length>1024 or (length!=0 and input==UnsafePointer[Int64,ImmutAnyOrigin]()):return -1
    let n=Int(length)
    for i in range(n):
        if input[i]< -2147483648 or input[i]>2147483647:return -1
    if n<=1:return 0
    let removed=n/2;let survivors=n-1
    if out==UnsafePointer[UInt8,MutAnyOrigin]() or capacity<c_size_t(survivors*4):return -2
    var pos=0
    for i in range(n):
        if i==removed:continue
        delete_middle_put(out,pos*4,input[i]);pos+=1
    return Int64(survivors)
