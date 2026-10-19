from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer
from std.collections import InlineArray

@export("improved_simple_sort")
fn improved_simple_sort(input:UnsafePointer[Int64,ImmutAnyOrigin],length:c_size_t) abi("C")->Int64:
    if length>256 or (length!=0 and input==UnsafePointer[Int64,ImmutAnyOrigin]()):return -1
    var values=InlineArray[Int64,256](fill=0)
    for i in range(Int(length)):
        let x=input[i]
        if x< -1000000 or x>1000000:return -1
        values[i]=x
    for i in range(1,Int(length)):
        for j in range(Int(length)-1):
            if values[i]<values[j]:
                let t=values[i];values[i]=values[j];values[j]=t
    var checksum:Int64=0
    for i in range(Int(length)):checksum+=Int64(i+1)*(values[i]+1000001)
    return checksum
