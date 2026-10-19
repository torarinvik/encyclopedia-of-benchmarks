from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin,MutAnyOrigin,UnsafePointer
fn opc_store(o:UnsafePointer[UInt8,MutAnyOrigin],at:Int,x:Int64):
    let b=UInt64(x)
    for j in range(8):o[at+j]=UInt8((b>>(8*j))&255)
@export("onepad_cipher")
fn onepad_cipher(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t,o:UnsafePointer[UInt8,MutAnyOrigin],cap:c_size_t) abi("C")->Int64:
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or n<2 or n>2050:return -1
    let mode=v[0];let count=v[1]
    if (mode!=0 and mode!=1) or count<0 or count>1024 or n!=c_size_t(2+2*count):return -1
    let needed=if mode==0:Int(count)*8 else:Int(count)
    if cap<c_size_t(needed) or (needed>0 and o==UnsafePointer[UInt8,MutAnyOrigin]()):return -2
    var staged_bytes=InlineArray[UInt8,8192](fill=UInt8(0));var staged_raw=InlineArray[UInt8,1024](fill=UInt8(0))
    for i in range(Int(count)):
        let data=v[2+i];let key=v[2+Int(count)+i]
        if key<1 or key>300:return -1
        if mode==0:
            if data<32 or data>126:return -1
            let encrypted=(data+key)*key;let bits=UInt64(encrypted)
            for j in range(8):staged_bytes[8*i+j]=UInt8((bits>>(8*j))&255)
        else:
            let square=key*key
            if data<square or (data-square)%key!=0:return -1
            let plain=(data-square)/key
            if plain<32 or plain>126:return -1
            staged_raw[i]=UInt8(plain)
    if mode==0:
        for i in range(needed):o[i]=staged_bytes[i]
    else:
        for i in range(Int(count)):o[i]=staged_raw[i]
    return Int64(needed)
