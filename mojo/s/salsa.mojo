from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
fn salsa_add(a:UInt32,b:UInt32)->UInt32:return UInt32((UInt64(a)+UInt64(b))&0xffffffff)
fn salsa_q(s:UnsafePointer[UInt32,MutAnyOrigin],a:Int,b:Int,c:Int,d:Int):
    s[b]=s[b]^((salsa_add(s[a],s[d])<<7)|(salsa_add(s[a],s[d])>>25))
    s[c]=s[c]^((salsa_add(s[b],s[a])<<9)|(salsa_add(s[b],s[a])>>23))
    s[d]=s[d]^((salsa_add(s[c],s[b])<<13)|(salsa_add(s[c],s[b])>>19))
    s[a]=s[a]^((salsa_add(s[d],s[c])<<18)|(salsa_add(s[d],s[c])>>14))
@export("salsa")
fn salsa(a:UnsafePointer[Int32,ImmutAnyOrigin],n:c_size_t,o:UnsafePointer[UInt8,MutAnyOrigin],cap:c_size_t) abi("C")->Int64:
    if a==UnsafePointer[Int32,ImmutAnyOrigin]() or n!=16:return -1
    if o==UnsafePointer[UInt8,MutAnyOrigin]() or cap<64:return -2
    var x=InlineArray[UInt32,16]();var s=InlineArray[UInt32,16]()
    for i in range(16):x[i]=bitcast[UInt32](a[i]);s[i]=x[i]
    for _ in range(10):
        salsa_q(s.unsafe_ptr(),0,4,8,12);salsa_q(s.unsafe_ptr(),5,9,13,1);salsa_q(s.unsafe_ptr(),10,14,2,6);salsa_q(s.unsafe_ptr(),15,3,7,11)
        salsa_q(s.unsafe_ptr(),0,1,2,3);salsa_q(s.unsafe_ptr(),5,6,7,4);salsa_q(s.unsafe_ptr(),10,11,8,9);salsa_q(s.unsafe_ptr(),15,12,13,14)
    for i in range(16):
        let z=salsa_add(s[i],x[i])
        for b in range(4):o[i*4+b]=UInt8((z>>UInt(8*b))&255)
    return 64
