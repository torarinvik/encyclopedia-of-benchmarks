from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
@export("word_count")
fn word_count(a:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t,o:UnsafePointer[UInt8,MutAnyOrigin],cap:c_size_t) abi("C")->Int64:
    if a==UnsafePointer[Int64,ImmutAnyOrigin]() or n<2 or n>1050:return -1
    let tl=a[0]
    if tl<0 or tl>999:return -1
    let qi=1+Int(tl)
    if qi>=Int(n) or a[qi]<0 or a[qi]>49 or n!=c_size_t(qi+1+Int(a[qi])):return -1
    let ql=Int(a[qi])
    for i in range(1,qi):if a[i]<1 or a[i]>127:return -1
    for i in range(qi+1,Int(n)):if a[i]<1 or a[i]>127:return -1
    var total=0;var matches=0;var start=0
    for end in range(Int(tl)+1):
        if end==Int(tl) or a[1+end]==32:
            let tok=end-start
            if tok>49:return -1
            if total>=20:return -2
            if tok==ql:
                var equal=true
                for j in range(tok):if a[1+start+j]!=a[qi+1+j]:equal=false
                if equal:matches+=1
            total+=1;start=end+1
    if o==UnsafePointer[UInt8,MutAnyOrigin]() or cap<16:return -2
    for j in range(2):
        let v=if j==0 then total else matches;let bits=bitcast[UInt64](Int64(v))
        for b in range(8):o[j*8+b]=UInt8((bits>>UInt(8*b))&255)
    return 16
