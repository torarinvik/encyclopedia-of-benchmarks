from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin,MutAnyOrigin,UnsafePointer
fn wr32rk(o:UnsafePointer[UInt8,MutAnyOrigin],at:Int,x:Int32):
    let b=UInt32(x);for j in range(4):o[at+j]=UInt8((b>>(j*8))&UInt32(255))
@export("reverse_kgroup")
fn reverse_kgroup(v:UnsafePointer[Int32,ImmutAnyOrigin],n:c_size_t,o:UnsafePointer[UInt8,MutAnyOrigin],cap:c_size_t) abi("C")->Int64:
    if v==UnsafePointer[Int32,ImmutAnyOrigin]() or n<1 or n>258:return -1
    let k=Int(v[0]);let size=Int(n)-1;if k<1 or k>256 or size>256:return -1
    if o==UnsafePointer[UInt8,MutAnyOrigin]() or cap<c_size_t(size*4):return -2
    var start=0
    while start+k<=size:
        for i in range(k):wr32rk(o,(start+i)*4,v[1+start+k-1-i])
        start+=k
    while start<size:wr32rk(o,start*4,v[start+1]);start+=1
    return Int64(size*4)
