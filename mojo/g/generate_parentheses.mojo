from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
from std.collections import InlineArray
fn gp_recurse(pairs:Int,opened:Int,closed:Int,buffer:InlineArray[UInt8,12],out:UnsafePointer[UInt8,MutAnyOrigin],cursor:Int)->Int:
    let pos=opened+closed
    if pos==2*pairs:
        for i in range(pos):out[cursor+i]=buffer[i]
        return cursor+pos
    var next=cursor
    if opened<pairs:
        var b=buffer;b[pos]=UInt8(40);next=gp_recurse(pairs,opened+1,closed,b,out,next)
    if closed<opened:
        var b=buffer;b[pos]=UInt8(41);next=gp_recurse(pairs,opened,closed+1,b,out,next)
    return next
@export("generate_parentheses")
fn generate_parentheses(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t,out:UnsafePointer[UInt8,MutAnyOrigin],cap:c_size_t) abi("C")->Int64:
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or n!=1 or v[0]<1 or v[0]>6:return -1
    let bytes=InlineArray[Int,7](0,2,8,30,112,420,1584)[Int(v[0])]
    if out==UnsafePointer[UInt8,MutAnyOrigin]() or cap<c_size_t(bytes):return -2
    let b=InlineArray[UInt8,12](fill=0)
    return Int64(gp_recurse(Int(v[0]),0,0,b,out,0))
