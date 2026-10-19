from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
fn swap_nodes_put(out:UnsafePointer[UInt8,MutAnyOrigin],pos:Int,value:Int64):
    let bits=bitcast[UInt64](value)
    for b in range(8):out[pos+b]=UInt8((bits>>UInt(b*8))&255)
@export("swap_nodes")
fn swap_nodes(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t,out:UnsafePointer[UInt8,MutAnyOrigin],cap:c_size_t) abi("C")->Int64:
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or n<3:return -1
    let nn=v[0]
    if nn<0 or nn>64 or n!=c_size_t(nn+3):return -1
    for i in range(Int(nn)):
        if v[1+i]< -2147483648 or v[1+i]>2147483647:return -1
    let a=v[1+Int(nn)];let b=v[2+Int(nn)]
    if a< -2147483648 or a>2147483647 or b< -2147483648 or b>2147483647:return -1
    let bytes=8+Int(nn)*8
    if out==UnsafePointer[UInt8,MutAnyOrigin]() or cap<c_size_t(bytes):return -2
    var ia=Int(nn);var ib=Int(nn)
    if a!=b:
        for i in range(Int(nn)):
            if ia==Int(nn) and v[1+i]==a:ia=i
            if ib==Int(nn) and v[1+i]==b:ib=i
    var staged=InlineArray[UInt8,520](fill=0);swap_nodes_put(staged.unsafe_ptr(),0,nn)
    for i in range(Int(nn)):
        var x=v[1+i]
        if ia<Int(nn) and ib<Int(nn):
            if i==ia:x=b
            elif i==ib:x=a
        swap_nodes_put(staged.unsafe_ptr(),8+8*i,x)
    for i in range(bytes):out[i]=staged[i]
    return bytes
