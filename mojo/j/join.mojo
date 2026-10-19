from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin,MutAnyOrigin,UnsafePointer
from std.collections import InlineArray
@export("join")
fn join(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t,o:UnsafePointer[UInt8,MutAnyOrigin],cap:c_size_t) abi("C")->Int64:
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or n<2 or n>2115:return -1
    let sl=Int(v[0]);let count=Int(v[1]);if sl<0 or sl>32 or count<0 or count>32:return -1
    var pos=2;var sep=InlineArray[UInt8,32](fill=0);var result=InlineArray[UInt8,3040](fill=0)
    if sl>Int(n)-pos:return -1
    for i in range(sl):let x=v[pos];pos+=1;if x<0 or x>127:return -1;sep[i]=UInt8(x)
    var used=0
    for item in range(count):
        if pos>=Int(n):return -1
        let len=Int(v[pos]);pos+=1;if len<0 or len>64 or len>Int(n)-pos:return -1
        if item>0:
            for j in range(sl):result[used]=sep[j];used+=1
        for j in range(len):
            let x=v[pos];pos+=1;if x<0 or x>127:return -1
            result[used]=UInt8(x);used+=1
    if pos!=Int(n):return -1
    if o==UnsafePointer[UInt8,MutAnyOrigin]() or cap<c_size_t(used):return -2
    for i in range(used):o[i]=result[i]
    return Int64(used)
