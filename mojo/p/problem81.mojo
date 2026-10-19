from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer
@export("problem81")
fn problem81(input:UnsafePointer[Int64,ImmutAnyOrigin],length:c_size_t) abi("C")->Int64:
    if input==UnsafePointer[Int64,ImmutAnyOrigin]() or length<1:return -1
    let d=input[0]
    if d<1 or d>80 or length!=c_size_t(1+d*d):return -1
    for i in range(1,Int(length)):if input[i]<0 or input[i]>9999:return -1
    var costs=InlineArray[Int64,80](fill=0);costs[0]=input[1]
    for col in range(1,Int(d)):costs[col]=costs[col-1]+input[1+col]
    for row in range(1,Int(d)):
        let off=1+row*Int(d);costs[0]+=input[off]
        for col in range(1,Int(d)):
            let above=costs[col];let left=costs[col-1];costs[col]=(above if above<left else left)+input[off+col]
    return costs[Int(d)-1]
