from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
fn suffix_pair_less(a:Int,b:Int,r:UnsafePointer[Int64,MutAnyOrigin],n:Int,step:Int)->Bool:
    if r[a]!=r[b]:return r[a]<r[b]
    let x= -1 if a+step>=n else r[a+step];let y= -1 if b+step>=n else r[b+step]
    return x<y
@export("suffix_array")
fn suffix_array(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t,out:UnsafePointer[UInt8,MutAnyOrigin],cap:c_size_t) abi("C")->Int64:
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or n<1 or n>65:return -1
    let count=v[0]
    if count<0 or count>64 or n!=c_size_t(1+count):return -1
    for i in range(Int(count)):if v[1+i]<0 or v[1+i]>127:return -1
    let bytes=Int(count)*8
    if out==UnsafePointer[UInt8,MutAnyOrigin]() or cap<c_size_t(bytes):return -2
    if count==0:return 0
    var sa=InlineArray[Int64,64](fill=0);var rank=InlineArray[Int64,64](fill=0);var next=InlineArray[Int64,64](fill=0)
    for i in range(Int(count)):sa[i]=i;rank[i]=v[1+i]
    var step=1
    while step<Int(count):
        for i in range(1,Int(count)):
            let key=sa[i];var pos=i
            while pos>0 and suffix_pair_less(Int(key),Int(sa[pos-1]),rank.unsafe_ptr(),Int(count),step):sa[pos]=sa[pos-1];pos-=1
            sa[pos]=key
        next[Int(sa[0])]=0
        for i in range(1,Int(count)):
            let a=Int(sa[i-1]);let b=Int(sa[i]);let x= -1 if a+step>=Int(count) else rank[a+step];let y= -1 if b+step>=Int(count) else rank[b+step]
            next[b]=next[a]+(1 if rank[a]!=rank[b] or x!=y else 0)
        for i in range(Int(count)):rank[i]=next[i]
        if rank[Int(sa[Int(count)-1])]==count-1:break
        step*=2
    for i in range(Int(count)):
        let bits=bitcast[UInt64](sa[i])
        for b in range(8):out[i*8+b]=UInt8((bits>>UInt(b*8))&255)
    return Int64(bytes)
