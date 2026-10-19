from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
@export("quadratic_probing")
fn quadratic_probing(a:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t,o:UnsafePointer[UInt8,MutAnyOrigin],cap:c_size_t) abi("C")->Int64:
    if a==UnsafePointer[Int64,ImmutAnyOrigin]() or n<2 or n>5:return -1
    let size=a[0];let count=a[1]
    if size<5 or size>31 or count<0 or count>3 or n!=c_size_t(count+2):return -1
    for i in range(Int(count)):if a[i+2]<0:return -1
    var table=InlineArray[Int64,31](fill= -1)
    for i in range(Int(count)):
        let key=a[i+2];let home=Int(key%size)
        if table[home]== -1:table[home]=key
        elif table[home]!=key:
            for probe in range(1,32):
                let slot=(home+probe*probe)%Int(size)
                if table[slot]== -1:
                    table[slot]=key;break
                if table[slot]==Int64(home):
                    table[slot]=key;break
    let words=Int(size)+1;let bytes=words*8
    if o==UnsafePointer[UInt8,MutAnyOrigin]() or cap<c_size_t(bytes):return -2
    for i in range(words):
        let x=Int64(size) if i==0 else table[i-1];let bits=bitcast[UInt64](x)
        for b in range(8):o[i*8+b]=UInt8((bits>>UInt(8*b))&255)
    return Int64(bytes)
