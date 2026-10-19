from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

@export("pkcs7_padding")
fn pkcs7_padding(v: UnsafePointer[Int64, ImmutAnyOrigin], n:c_size_t, out:UnsafePointer[UInt8,MutAnyOrigin], cap:c_size_t) abi("C")->Int64:
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or n<5 or n>69:return -1
    let op=v[0];let block=v[1];let off=v[2];let raw=v[3]
    if op<0 or op>2 or block<1 or block>16 or raw<1 or raw>64 or (op==0 and (off<0 or off>raw)) or n!=c_size_t(raw+4):return -1
    let len=Int(raw)
    for i in range(len):if v[4+i]<0 or v[4+i]>255:return -1
    let pad=Int(v[3+len])
    var outlen=0
    if op==0:
        let p=Int(block)-len%Int(block)
        if Int(off)+p>len:return -1
        outlen=len+1
    elif op==1:
        if len%Int(block)!=0 or pad<1 or pad>Int(block):return -1
        for i in range(len-pad,len):if v[4+i]!=Int64(pad):return -1
        outlen=len-pad
    else:
        if pad<1 or pad>len:return -1
        for i in range(len-pad,len):if v[4+i]!=Int64(pad):return -1
        outlen=1
    if out==UnsafePointer[UInt8,MutAnyOrigin]() or cap<c_size_t(outlen):return -2
    if op==0:
        let p=Int(block)-len%Int(block);out[0]=UInt8(p)
        for i in range(len):out[i+1]=UInt8(p if i>=Int(off) and i<Int(off)+p else v[4+i])
    elif op==1:
        for i in range(outlen):out[i]=UInt8(v[4+i])
    else:out[0]=UInt8(pad)
    return Int64(outlen)
