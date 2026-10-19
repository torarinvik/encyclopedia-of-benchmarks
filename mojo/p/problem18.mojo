from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer
@export("problem18")
fn problem18(input:UnsafePointer[Int64,ImmutAnyOrigin],length:c_size_t) abi("C")->Int64:
    if input==UnsafePointer[Int64,ImmutAnyOrigin]() or length<2 or length>121:return -1
    let rows=input[0]
    if rows<1 or rows>15 or length!=c_size_t(rows*(rows+1)//2+1):return -1
    var best=InlineArray[Int64,120](fill=0);let values=Int(length-1)
    for i in range(values):
        let value=input[i+1]
        if value<0 or value>1000000:return -1
        best[i]=value
    for row in range(1,Int(rows)):
        let level=Int(rows)-1-row;let ps=level*(level+1)//2;let cs=(level+1)*(level+2)//2
        for col in range(level+1):
            let left=best[cs+col];let right=best[cs+col+1]
            best[ps+col]+=left if left>right else right
    return best[0]
