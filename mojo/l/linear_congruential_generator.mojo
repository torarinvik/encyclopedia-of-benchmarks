from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin,MutAnyOrigin,UnsafePointer
fn lcg_put(out:UnsafePointer[UInt8,MutAnyOrigin],at:Int,x:UInt64):
    for i in range(8):out[at+i]=UInt8((x>>(8*i))&255)
@export("linear_congruential_generator")
fn linear_congruential_generator(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t,out:UnsafePointer[UInt8,MutAnyOrigin],cap:c_size_t) abi("C")->Int64:
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or n!=5:return -1
    let seed=v[0];let mul=v[1];let inc=v[2];let mod=v[3];let count=v[4]
    if mod<2 or mod>4294967296 or seed<0 or seed>=mod or mul<0 or mul>65535 or inc<0 or inc>4294967295 or count<0 or count>512:return -1
    let required=8*Int(count)
    if cap<c_size_t(required) or (required!=0 and out==UnsafePointer[UInt8,MutAnyOrigin]()):return -2
    var state=UInt64(seed)
    for i in range(Int(count)):
        state=(UInt64(mul)*state+UInt64(inc))%UInt64(mod);lcg_put(out,i*8,state)
    return Int64(required)
