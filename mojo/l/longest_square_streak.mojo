from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin,MutAnyOrigin,UnsafePointer
fn ls_read(w:UnsafePointer[UInt8,MutAnyOrigin],x:Int)->Int32:
    let p=x*4
    let u=UInt32(w[p])|(UInt32(w[p+1])<<8)|(UInt32(w[p+2])<<16)|(UInt32(w[p+3])<<24)
    return bitcast[Int32](u)
fn ls_write(w:UnsafePointer[UInt8,MutAnyOrigin],x:Int,state:Int32):
    let u=bitcast[UInt32](state);let p=x*4
    w[p]=UInt8(u&255);w[p+1]=UInt8((u>>8)&255);w[p+2]=UInt8((u>>16)&255);w[p+3]=UInt8((u>>24)&255)
fn ls_from(w:UnsafePointer[UInt8,MutAnyOrigin],x:Int)->Int64:
    let state=ls_read(w,x)
    if state>1:return Int64(state)-1
    var length:Int64=1;let square=UInt64(x)*UInt64(x)
    if square<=100000 and ls_read(w,Int(square))!=0:length+=ls_from(w,Int(square))
    ls_write(w,x,Int32(length+1));return length
@export("longest_square_streak")
fn longest_square_streak(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t,w:UnsafePointer[UInt8,MutAnyOrigin],wcap:c_size_t) abi("C")->Int64:
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or n<3 or n>100001 or v[0]<2 or v[0]>100000 or n!=c_size_t(v[0]+1):return -1
    let count=Int(v[0])
    for i in range(count):
        if v[i+1]<2 or v[i+1]>100000:return -1
    if w==UnsafePointer[UInt8,MutAnyOrigin]() or wcap<400004:return -2
    for i in range(400004):w[i]=0
    for i in range(count):ls_write(w,Int(v[i+1]),1)
    var best:Int64=1
    for i in range(count):best=max(best,ls_from(w,Int(v[i+1])))
    return if best>=2:best else:-1
