from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
@export("transposition_cipher")
fn transposition_cipher(a:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t,o:UnsafePointer[UInt8,MutAnyOrigin],cap:c_size_t) abi("C")->Int64:
    if a==UnsafePointer[Int64,ImmutAnyOrigin]() or n<6 or n>259:return -1
    let mode=a[0];let key0=a[1];let len0=a[2]
    if (mode!=0 and mode!=1) or len0<3 or len0>256 or key0<2 or key0>=len0 or n!=c_size_t(3+len0):return -1
    let key=Int(key0);let count=Int(len0)
    for i in range(count):
        if a[3+i]<0 or a[3+i]>127:return -1
    if o==UnsafePointer[UInt8,MutAnyOrigin]() or cap<c_size_t(count):return -2
    var out=InlineArray[UInt8,256]()
    if mode==0:
        var wr=0
        for col in range(key):
            var idx=col
            while idx<count:out[wr]=UInt8(a[3+idx]);wr+=1;idx+=key
    else:
        let cols=(count+key-1)/key;let shaded=cols*key-count;let lastrows=key-shaded
        var offsets=InlineArray[Int,256]();var seen=InlineArray[Int,256]();var total=0
        for col in range(cols):offsets[col]=total;total+=if col+1==cols then lastrows else key
        var row=0;var col=0
        for i in range(count):
            out[offsets[col]+seen[col]]=UInt8(a[3+i]);seen[col]+=1;col+=1
            if col==cols or (col==cols-1 and row>=lastrows):col=0;row+=1
    for i in range(count):o[i]=out[i]
    return Int64(count)
