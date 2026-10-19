from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
@export("product_cipher")
fn product_cipher(input:UnsafePointer[Int64,ImmutAnyOrigin],length:c_size_t,output:UnsafePointer[UInt8,MutAnyOrigin],capacity:c_size_t) abi("C")->Int64:
    if input==UnsafePointer[Int64,ImmutAnyOrigin]() or length<2 or length>259:return -1
    if input[0]<1 or input[0]>64 or input[1]<0 or input[1]>256:return -1
    let cols=Int(input[0]);let textlen=Int(input[1])
    if length!=c_size_t(2+textlen):return -1
    for i in range(textlen):
        if input[2+i]<0 or input[2+i]>127 or input[2+i]==10 or input[2+i]==13:return -1
    if textlen==0:return 0
    let padded=((textlen+cols-1)//cols)*cols
    if output==UnsafePointer[UInt8,MutAnyOrigin]() or capacity<c_size_t(padded):return -2
    var staged=InlineArray[UInt8,315](fill=0)
    for i in range(textlen):staged[i]=UInt8(input[2+i]+5)
    for i in range(textlen,padded):staged[i]=47
    let rows=padded//cols;var pos=0
    for c in range(cols):
        for r in range(rows):output[pos]=staged[r*cols+c];pos+=1
    return Int64(pos)
