from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer
fn macs_step(h:UInt64,b:UInt8)->UInt64:return (h^UInt64(b))*1099511628211
@export("mono_alphabetic_ciphers")
fn mono_alphabetic_ciphers(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t) abi("C")->Int64:
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or n<2 or n>157:return -1
    let op=v[0];let t=Int(v[1]);if (op!=0 and op!=1) or t<0 or t>128 or Int(n)!=28+t:return -1
    var seen=InlineArray[Int64,26](fill=0);var inv=InlineArray[Int64,26](fill=0)
    for i in range(26):let x=v[2+i];if x<65 or x>90 or seen[Int(x-65)]!=0:return -1;seen[Int(x-65)]=1;inv[Int(x-65)]=Int64(i)
    for i in range(t):if v[28+i]<32 or v[28+i]>126:return -1
    var h:UInt64=14695981039346656037
    for b in range(8):h=macs_step(h,UInt8((UInt64(t)>>(8*b))&255))
    for i in range(t):
        let x=v[28+i];var y=x
        if (x>=65 and x<=90) or (x>=97 and x<=122):
            let low=x>=97;let ix=Int(if low:x-97 else:x-65);let pos=Int(if op==0:inv[ix] else:Int64(ix));let target=if op==0:Int64(65+pos) else:v[2+pos];y=target+(if low:32 else:0)
        h=macs_step(h,UInt8(y))
    return Int64(h&0x7fffffffffffffff)
