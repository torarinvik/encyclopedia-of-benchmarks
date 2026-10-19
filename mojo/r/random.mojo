from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin,MutAnyOrigin,UnsafePointer
fn pcg_store(o:UnsafePointer[UInt8,MutAnyOrigin],at:Int,x:UInt32):
    for j in range(4):o[at+j]=UInt8((x>>(8*j))&255)
fn pcg_rot(x:UInt32,r:UInt32)->UInt32:
    let left=(32-r)&31
    return (x>>r)|(x<<left)
@export("pcg32_random")
fn pcg32_random(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t,o:UnsafePointer[UInt8,MutAnyOrigin],cap:c_size_t) abi("C")->Int64:
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or n!=4:return -1
    if v[2]<0 or v[3]<0 or v[3]>256:return -1
    let seed=bitcast[UInt64](v[0]);let mult=bitcast[UInt64](v[1]);let inc=(UInt64(v[2])<<1)|1;let count=Int(v[3]);let bytes=count*4
    var state=seed+inc;state=state*mult+inc
    if o==UnsafePointer[UInt8,MutAnyOrigin]() or cap<c_size_t(bytes):return -2
    for i in range(count):
        let old=state;let rot=UInt32(old>>59);state=state*mult+inc;let shifted=UInt32((old^(old>>18))>>27)
        pcg_store(o,i*4,pcg_rot(shifted,rot))
    return Int64(bytes)
