from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin,MutAnyOrigin,UnsafePointer
fn wr64rkg(o:UnsafePointer[UInt8,MutAnyOrigin],at:Int,x:Int64):
    let b=UInt64(x);for j in range(8):o[at+j]=UInt8((b>>(j*8))&UInt64(255))
@export("reverse_k_group")
fn reverse_k_group(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t,o:UnsafePointer[UInt8,MutAnyOrigin],cap:c_size_t) abi("C")->Int64:
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or n<2 or n>258:return -1
    let size=Int(v[0]);let k=Int(v[1]);if size<0 or size>256 or k<1 or k>256 or Int(n)!=size+2:return -1
    if o==UnsafePointer[UInt8,MutAnyOrigin]() or cap<c_size_t(size*8):return -2
    var start=0
    while start+k<=size:
        for i in range(k):wr64rkg(o,(start+i)*8,v[2+start+k-1-i])
        start+=k
    while start<size:wr64rkg(o,start*8,v[2+start]);start+=1
    return Int64(size*8)
