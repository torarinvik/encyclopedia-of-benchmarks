from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer
from std.collections import InlineArray

@export("iso7816_d4_padding")
fn iso7816_d4_padding(input:UnsafePointer[Int64,ImmutAnyOrigin],length:c_size_t) abi("C")->Int64:
    if input==UnsafePointer[Int64,ImmutAnyOrigin]() or length<3 or length>27:return -1
    let mode=input[0];let block=input[1];let n=input[2]
    if mode<0 or mode>2 or (mode==0 and (block<1 or block>8)) or (mode!=0 and block!=0) or n<0 or n>24 or length!=c_size_t(n+3):return -1
    var bytes=InlineArray[UInt8,32](fill=0)
    for i in range(Int(n)):
        if input[i+3]<0 or input[i+3]>255:return -1
        bytes[i]=UInt8(input[i+3])
    if mode==0:
        let out=(Int(n)//Int(block)+1)*Int(block)
        if out>32:return -1
        bytes[Int(n)]=128
        for i in range(Int(n)+1,out):bytes[i]=0
        return Int64(out-Int(n))
    if mode==1:
        var i=Int(n)-1
        while i>=0 and bytes[i]==0:i-=1
        return Int64(i) if i>=0 and bytes[i]==128 else -1
    var marker= -1;var zero_suffix=True;var j=Int(n)-1
    while j>=0:
        if zero_suffix and bytes[j]==128:marker=j
        if bytes[j]!=0:zero_suffix=False
        j-=1
    return Int64(Int(n)-marker) if marker>=0 else -1
