from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer
@export("problem67")
fn problem67(input:UnsafePointer[Int64,ImmutAnyOrigin],length:c_size_t) abi("C")->Int64:
    if input==UnsafePointer[Int64,ImmutAnyOrigin]() or length<2 or length>5051:return -1
    let rows=input[0]
    if rows<1 or rows>100 or length!=c_size_t(rows*(rows+1)//2+1):return -1
    var best=InlineArray[Int64,5050](fill=0);let count=Int(length-1)
    for i in range(count):
        let v=input[i+1]
        if v<0 or v>1000000:return -1
        best[i]=v
    var row=Int(rows)-1
    while row>0:
        let ps=(row-1)*row//2;let cs=row*(row+1)//2
        for col in range(row):
            let left=best[cs+col];let right=best[cs+col+1]
            best[ps+col]+=left if left>right else right
        row-=1
    return best[0]
