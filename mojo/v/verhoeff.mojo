from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer
comptime D:InlineArray[UInt8,100]=InlineArray[UInt8,100](0,1,2,3,4,5,6,7,8,9,1,2,3,4,0,6,7,8,9,5,2,3,4,0,1,7,8,9,5,6,3,4,0,1,2,8,9,5,6,7,4,0,1,2,3,9,5,6,7,8,5,9,8,7,6,0,4,3,2,1,6,5,9,8,7,1,0,4,3,2,7,6,5,9,8,2,1,0,4,3,8,7,6,5,9,3,2,1,0,4,9,8,7,6,5,4,3,2,1,0)
comptime P:InlineArray[UInt8,80]=InlineArray[UInt8,80](0,1,2,3,4,5,6,7,8,9,1,5,7,6,2,8,3,0,9,4,5,8,0,3,7,9,6,1,4,2,8,9,1,6,0,4,3,5,2,7,9,4,5,3,1,2,6,8,7,0,4,2,8,6,5,7,3,9,0,1,2,7,9,3,8,0,6,4,1,5,7,0,4,6,9,1,3,2,5,8)
@export("verhoeff")
fn verhoeff(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t) abi("C")->Int64:
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or n==0 or n>1024:return -1
    var c=0
    for i in range(Int(n)):
        let d=v[Int(n)-i-1]
        if d<0 or d>9:return -1
        c=Int(D[c*10+Int(P[(i%8)*10+Int(d)])])
    return Int64(c==0)
