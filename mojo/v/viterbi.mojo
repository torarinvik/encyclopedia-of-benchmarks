from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
@export("viterbi")
fn viterbi(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t,o:UnsafePointer[UInt8,MutAnyOrigin],cap:c_size_t) abi("C")->Int64:
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or n==0 or n>64:return -1
    for i in range(Int(n)):if v[i]<0 or v[i]>2:return -1
    if o==UnsafePointer[UInt8,MutAnyOrigin]() or cap<c_size_t(Int(n)*8):return -2
    let start=InlineArray[Float64,2](0.6,0.4);let tr=InlineArray[Float64,4](0.7,0.3,0.4,0.6);let em=InlineArray[Float64,6](0.5,0.4,0.1,0.1,0.3,0.6)
    var s0=start[0]*em[Int(v[0])];var s1=start[1]*em[3+Int(v[0])]
    var back=InlineArray[UInt8,128](fill=0)
    for t in range(1,Int(n)):
        var ns=InlineArray[Float64,2](fill=0.0)
        for s in range(2):
            let a=s0*tr[s]*em[s*3+Int(v[t])];let b=s1*tr[2+s]*em[(2+s)*3+Int(v[t])]
            let prev=if b>a then 1 else 0
            back[t*2+s]=UInt8(prev);ns[s]=if prev==0 then a else b
        s0=ns[0];s1=ns[1]
    var state=if s1>s0 then 1 else 0;var path=InlineArray[Int64,64](fill=0);path[Int(n)-1]=state
    if n>1:
        for t in range(Int(n)-1,0,-1):state=Int(back[t*2+state]);path[t-1]=state
    for i in range(Int(n)):
        let bits=bitcast[UInt64](path[i]);for b in range(8):o[i*8+b]=UInt8((bits>>UInt(8*b))&255)
    return Int64(Int(n)*8)
