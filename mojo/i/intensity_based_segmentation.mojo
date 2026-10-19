from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

@export("intensity_based_segmentation")
fn intensity_based_segmentation(input:UnsafePointer[Int64,ImmutAnyOrigin],length:c_size_t) abi("C")->Int64:
    if input==UnsafePointer[Int64,ImmutAnyOrigin]() or length<2 or length>12:return -1
    let k=input[0]
    if k<0 or k>4 or length<=c_size_t(k+1) or length>c_size_t(k+8):return -1
    for i in range(1,Int(length)):
        if input[i]<0 or input[i]>255:return -1
    var result:Int64=0;var place:Int64=1
    for pos in range(Int(k)+1,Int(length)):
        var label:Int64=0
        for i in range(Int(k)):
            if input[pos]>input[1+i]:label=Int64(i+1)
        result+=label*place;place*=5
    return result
