from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin,MutAnyOrigin,UnsafePointer
fn op_put(o:UnsafePointer[UInt8,MutAnyOrigin],at:Int,x:Int64):
    let b=UInt32(Int32(x))
    for j in range(4):o[at+j]=UInt8((b>>(8*j))&255)
@export("operators")
fn operators(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t,o:UnsafePointer[UInt8,MutAnyOrigin],cap:c_size_t) abi("C")->Int64:
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or n<5:return -1
    let op=v[0];let ra=v[1];let ca=v[2]
    if (op!=0 and op!=1) or ra<1 or ra>16 or ca<0 or ca>16 or ra*ca>256:return -1
    let a_count=Int(ra*ca);let pb=3+a_count
    if n<c_size_t(pb+2):return -1
    let rb=v[pb];let cb=v[pb+1]
    if rb<1 or rb>16 or cb<0 or cb>16 or rb*cb>256 or n!=c_size_t(pb+2+rb*cb):return -1
    for i in range(a_count):if v[3+i]<-1000000 or v[3+i]>1000000:return -1
    for i in range(Int(rb*cb)):if v[pb+2+i]<-1000000 or v[pb+2+i]>1000000:return -1
    if ra!=rb or ca!=cb:return -1
    if cap<c_size_t(a_count*4) or (a_count>0 and o==UnsafePointer[UInt8,MutAnyOrigin]()):return -2
    for i in range(a_count):op_put(o,i*4,if op==0:v[3+i]+v[pb+2+i] else:v[3+i]-v[pb+2+i])
    return Int64(a_count)
