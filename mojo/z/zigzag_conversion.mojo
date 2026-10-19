from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
fn letter(x:Int64)->Bool:return (x>=65 and x<=90) or (x>=97 and x<=122)
@export("zigzag_conversion")
fn zigzag_conversion(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t,o:UnsafePointer[UInt8,MutAnyOrigin],cap:c_size_t) abi("C")->Int64:
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or n<1 or n>1025:return -1
    let rows=v[0];let len=Int(n)-1
    if rows<1 or rows>1024:return -1
    for i in range(len):if not letter(v[i+1]):return -1
    if cap<c_size_t(len) or (len>0 and o==UnsafePointer[UInt8,MutAnyOrigin]()):return -2
    if len==0:return 0
    if rows==1 or rows>=len:
        for i in range(len):o[i]=UInt8(v[i+1])
        return Int64(len)
    let r=Int(rows);let cycle=2*(r-1);var written=0
    for row in range(r):
        var index=row
        while index<len:
            o[written]=UInt8(v[index+1]);written+=1
            if row!=0 and row+1!=r:
                let diagonal=cycle-2*row
                index+=diagonal
                if index<len:o[written]=UInt8(v[index+1]);written+=1
                index+=cycle-diagonal
            else:index+=cycle
    return Int64(written)
