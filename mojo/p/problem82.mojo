from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer
@export("problem82")
fn problem82(input:UnsafePointer[Int64,ImmutAnyOrigin],length:c_size_t) abi("C")->Int64:
    if input==UnsafePointer[Int64,ImmutAnyOrigin]() or length<3:return -1
    let rows=input[0];let cols=input[1]
    if rows<1 or rows>80 or cols<1 or cols>80 or length!=c_size_t(2+rows*cols):return -1
    for i in range(2,Int(length)):if input[i]<0 or input[i]>9999:return -1
    var costs=InlineArray[Int64,80](fill=0)
    for r in range(Int(rows)):costs[r]=input[2+r*Int(cols)]
    for col in range(1,Int(cols)):
        let off=2+col
        for r in range(Int(rows)):costs[r]+=input[off+r*Int(cols)]
        for r in range(1,Int(rows)):
            let above=costs[r-1]+input[off+r*Int(cols)]
            if above<costs[r]:costs[r]=above
        var r=Int(rows)-1
        while r>0:
            let below=costs[r]+input[off+(r-1)*Int(cols)]
            if below<costs[r-1]:costs[r-1]=below
            r-=1
    var best=costs[0]
    for r in range(1,Int(rows)):if costs[r]<best:best=costs[r]
    return best
