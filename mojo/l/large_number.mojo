from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

@export("large_number_add")
fn large_number_add(v: UnsafePointer[Int64, ImmutAnyOrigin], n:c_size_t, out:UnsafePointer[UInt8,MutAnyOrigin], cap:c_size_t) abi("C")->Int64:
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or n<2 or n>131:return -1
    let a=v[0];let b=v[1]
    if a<1 or a>64 or b<1 or b>64 or n!=c_size_t(2+a+b):return -1
    for i in range(Int(a+b)):
        let d=v[2+i]
        if d<48 or d>57:return -1
    if (a>1 and v[2]==48) or (b>1 and v[2+Int(a)]==48):return -1
    var rev=InlineArray[UInt8,65](fill=UInt8(0));var len=0;var carry:Int64=0
    let m=max(Int(a),Int(b))
    for i in range(m):
        var z=carry
        if i<Int(a):z+=v[2+Int(a)-1-i]-48
        if i<Int(b):z+=v[2+Int(a)+Int(b)-1-i]-48
        rev[len]=UInt8(48+z%10);len+=1;carry=z/10
    if carry!=0:rev[len]=UInt8(48+carry);len+=1
    if out==UnsafePointer[UInt8,MutAnyOrigin]() or cap<c_size_t(len):return -2
    for i in range(len):out[i]=rev[len-1-i]
    return Int64(len)
