from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
@export("sum_even_after_queries")
fn sum_even_after_queries(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t,out:UnsafePointer[UInt8,MutAnyOrigin],cap:c_size_t) abi("C")->Int64:
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or n<5 or n>4002:return -1
    let nn=v[0];let qn=v[1]
    if nn<1 or nn>1000 or qn<1 or qn>1000 or n!=c_size_t(2+nn+2*qn):return -1
    var vals=InlineArray[Int64,1000](fill=0);var sum:Int64=0
    for i in range(Int(nn)):
        let x=v[2+i]
        if x<1 or x>1000:return -1
        vals[i]=x
        if x%2==0:sum+=x
    for q in range(Int(qn)):
        let off=2+Int(nn)+2*q;let delta=v[off];let idx=v[off+1]
        if delta< -1000 or delta>1000 or idx<0 or idx>=nn:return -1
    if out==UnsafePointer[UInt8,MutAnyOrigin]() or cap<c_size_t(Int(qn)*4):return -2
    var bytes=InlineArray[UInt8,4000](fill=0)
    for q in range(Int(qn)):
        let off=2+Int(nn)+2*q;let delta=v[off];let idx=Int(v[off+1])
        if vals[idx]%2==0:sum-=vals[idx]
        vals[idx]+=delta
        if vals[idx]%2==0:sum+=vals[idx]
        let bits=bitcast[UInt32](Int32(sum))
        for b in range(4):bytes[q*4+b]=UInt8((bits>>UInt(b*8))&255)
    for i in range(Int(qn)*4):out[i]=bytes[i]
    return qn
