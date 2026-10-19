from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

fn ida_store(out:UnsafePointer[UInt8,MutAnyOrigin],i:Int,x:Int64):
    let bits=UInt32(Int32(x))
    for b in range(4):out[4*i+b]=UInt8((bits>>(8*b))&255)

@export("insert_delete_in_array")
fn insert_delete_in_array(input:UnsafePointer[Int64,ImmutAnyOrigin],length:c_size_t,
                          output:UnsafePointer[UInt8,MutAnyOrigin],capacity:c_size_t) abi("C")->Int64:
    if input==UnsafePointer[Int64,ImmutAnyOrigin]() or length<4 or length>260:return -1
    let op=input[0];let n=input[1];let pos=input[2];let element=input[3]
    if (op!=0 and op!=1) or n<0 or n>256 or length!=c_size_t(n+4) or pos<0 or (op==0 and pos>n) or (op==1 and pos>=n) or (op==1 and element!=0):return -1
    for i in range(Int(n)):
        if input[4+i]< -2147483648 or input[4+i]>2147483647:return -1
    if op==0 and (element< -2147483648 or element>2147483647):return -1
    let outn=Int(n)+(1 if op==0 else 0);let bytes=outn*4
    if capacity<c_size_t(bytes) or (outn>0 and output==UnsafePointer[UInt8,MutAnyOrigin]()):return -2
    for i in range(outn):
        var x:Int64=0
        if op==0:x=input[4+i] if i<Int(pos) else element if i==Int(pos) else input[3+i]
        else:x=input[4+i] if i<Int(pos) else input[5+i]
        ida_store(output,i,x)
    return Int64(bytes)
