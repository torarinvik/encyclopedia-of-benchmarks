from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer
fn mac_step(h:UInt64,b:UInt8)->UInt64:return (h^UInt64(b))*1099511628211
@export("mono_alphabetic_cipher")
fn mono_alphabetic_cipher(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t) abi("C")->Int64:
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or n<2 or n>183:return -1
    let op=v[0];let t=Int(v[1]);if (op!=0 and op!=1) or t<0 or t>128 or Int(n)!=54+t:return -1
    var ks=InlineArray[Int64,26](fill=0);var as=InlineArray[Int64,26](fill=0);var ki=InlineArray[Int64,26](fill=0);var ai=InlineArray[Int64,26](fill=0)
    for i in range(26):
        let k=v[2+i];let a=v[28+i];if k<65 or k>90 or a<65 or a>90 or ks[Int(k-65)]!=0 or as[Int(a-65)]!=0:return -1
        ks[Int(k-65)]=1;as[Int(a-65)]=1;ki[Int(k-65)]=Int64(i);ai[Int(a-65)]=Int64(i)
    var olen=0
    for i in range(t):let x=v[54+i];if x==32:olen+=1 elif x>=48 and x<=57:pass elif (x>=65 and x<=90) or (x>=97 and x<=122):olen+=1 else:return -1
    var h:UInt64=14695981039346656037
    for b in range(8):h=mac_step(h,UInt8((UInt64(olen)>>(8*b))&255))
    for i in range(t):
        let x=v[54+i]
        if x>=48 and x<=57:continue
        var y=x
        if x!=32:
            let lower=x>=97;let letter=Int(if lower:x-97 else:x-65);let pos=Int(if op==0:ai[letter] else:ki[letter]);let target=if op==0:v[2+pos] else:v[28+pos]
            y=target+(if lower:32 else:0)
        h=mac_step(h,UInt8(y))
    return Int64(h&0x7fffffffffffffff)
