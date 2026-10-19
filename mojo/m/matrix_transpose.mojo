from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
from std.collections import InlineArray

fn mt_store(out: UnsafePointer[UInt8,MutAnyOrigin],pos:Int,x:Int64):
    let bits=bitcast[UInt64](x)
    for b in range(8):out[pos+b]=UInt8((bits>>UInt64(8*b))&255)

@export("matrix_transpose")
fn matrix_transpose(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t,out:UnsafePointer[UInt8,MutAnyOrigin],cap:c_size_t) abi("C")->Int64:
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or n<2 or n>1027:return -1
    let rows=Int(v[0]);let cols=Int(v[1])
    if rows<1 or rows>32 or cols<1 or cols>32 or n!=c_size_t(2+rows*cols):return -1
    var result=InlineArray[Int64,1024](fill=0)
    for r in range(rows):for c in range(cols):
        let x=v[2+r*cols+c]
        if x< -2147483648 or x>2147483647:return -1
        result[c*rows+r]=x
    let bytes=8*(2+rows*cols)
    if out==UnsafePointer[UInt8,MutAnyOrigin]() or cap<c_size_t(bytes):return -2
    mt_store(out,0,Int64(cols));mt_store(out,8,Int64(rows))
    for i in range(rows*cols):mt_store(out,16+i*8,result[i])
    return Int64(bytes)
