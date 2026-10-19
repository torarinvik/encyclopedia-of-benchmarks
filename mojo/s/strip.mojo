from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
fn strip_has(x:Int64,v:UnsafePointer[Int64,ImmutAnyOrigin],start:Int,setlen:Int)->Bool:
    if setlen<0:return x==9 or x==10 or x==13 or x==32
    for j in range(setlen):if v[start+j]==x:return True
    return False
@export("strip")
fn strip(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t,o:UnsafePointer[UInt8,MutAnyOrigin],cap:c_size_t) abi("C")->Int64:
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or n<2 or n>386:return -1
    let tv=v[0]
    if tv<0 or tv>256:return -1
    let tl=Int(tv);let si=tl+1
    if si>=Int(n):return -1
    let sl=v[si]
    if sl< -1 or sl>128 or n!=c_size_t(si+1+(if sl<0 then 0 else Int(sl))):return -1
    for i in range(1,si):if v[i]<0 or v[i]>127:return -1
    if sl>=0:
        for i in range(Int(sl)):if v[si+1+i]<0 or v[si+1+i]>127:return -1
    var start=0;var end=tl
    while start<end and strip_has(v[1+start],v,si+1,Int(sl)):start+=1
    while end>start and strip_has(v[end],v,si+1,Int(sl)):end-=1
    let outlen=end-start
    if cap<c_size_t(outlen) or (outlen>0 and o==UnsafePointer[UInt8,MutAnyOrigin]()):return -2
    for i in range(outlen):o[i]=UInt8(v[1+start+i])
    return Int64(outlen)
