from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
fn sh256_add(a:UInt32,b:UInt32)->UInt32:return UInt32((UInt64(a)+UInt64(b))&0xffffffff)
fn sh256_r(x:UInt32,n:Int)->UInt32:return (x>>UInt(n))|(x<<UInt(32-n))
@export("sha256")
fn sha256(a:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t,o:UnsafePointer[UInt8,MutAnyOrigin],cap:c_size_t) abi("C")->Int64:
    if n>4096 or (n>0 and a==UnsafePointer[Int64,ImmutAnyOrigin]()):return -1
    for i in range(Int(n)):if a[i]<0 or a[i]>255:return -1
    if o==UnsafePointer[UInt8,MutAnyOrigin]() or cap<32:return -2
    let k=InlineArray[UInt32,64](0x428a2f98,0x71374491,0xb5c0fbcf,0xe9b5dba5,0x3956c25b,0x59f111f1,0x923f82a4,0xab1c5ed5,0xd807aa98,0x12835b01,0x243185be,0x550c7dc3,0x72be5d74,0x80deb1fe,0x9bdc06a7,0xc19bf174,0xe49b69c1,0xefbe4786,0x0fc19dc6,0x240ca1cc,0x2de92c6f,0x4a7484aa,0x5cb0a9dc,0x76f988da,0x983e5152,0xa831c66d,0xb00327c8,0xbf597fc7,0xc6e00bf3,0xd5a79147,0x06ca6351,0x14292967,0x27b70a85,0x2e1b2138,0x4d2c6dfc,0x53380d13,0x650a7354,0x766a0abb,0x81c2c92e,0x92722c85,0xa2bfe8a1,0xa81a664b,0xc24b8b70,0xc76c51a3,0xd192e819,0xd6990624,0xf40e3585,0x106aa070,0x19a4c116,0x1e376c08,0x2748774c,0x34b0bcb5,0x391c0cb3,0x4ed8aa4a,0x5b9cca4f,0x682e6ff3,0x748f82ee,0x78a5636f,0x84c87814,0x8cc70208,0x90befffa,0xa4506ceb,0xbef9a3f7,0xc67178f2)
    let padded=((Int(n)+72)/64)*64;var msg=InlineArray[UInt8,4224]()
    for i in range(Int(n)):msg[i]=UInt8(a[i])
    msg[Int(n)]=128;let bits=UInt64(n)*8
    for j in range(8):msg[padded-1-j]=UInt8((bits>>UInt(8*j))&255)
    var h=InlineArray[UInt32,8](0x6a09e667,0xbb67ae85,0x3c6ef372,0xa54ff53a,0x510e527f,0x9b05688c,0x1f83d9ab,0x5be0cd19)
    for off in range(0,padded,64):
        var w=InlineArray[UInt32,64]()
        for i in range(16):w[i]=(UInt32(msg[off+4*i])<<24)|(UInt32(msg[off+4*i+1])<<16)|(UInt32(msg[off+4*i+2])<<8)|UInt32(msg[off+4*i+3])
        for i in range(16,64):
            let x=w[i-15];let y=w[i-2];let s0=sh256_r(x,7)^sh256_r(x,18)^(x>>3);let s1=sh256_r(y,17)^sh256_r(y,19)^(y>>10)
            w[i]=sh256_add(sh256_add(sh256_add(w[i-16],s0),w[i-7]),s1)
        var aa=h[0];var bb=h[1];var cc=h[2];var dd=h[3];var ee=h[4];var ff=h[5];var gg=h[6];var hh=h[7]
        for i in range(64):
            let s1=sh256_r(ee,6)^sh256_r(ee,11)^sh256_r(ee,25);let ch=(ee&ff)^((~ee)&gg);let t1=sh256_add(sh256_add(sh256_add(sh256_add(hh,s1),ch),k[i]),w[i])
            let s0=sh256_r(aa,2)^sh256_r(aa,13)^sh256_r(aa,22);let maj=(aa&bb)^(aa&cc)^(bb&cc);let t2=sh256_add(s0,maj)
            hh=gg;gg=ff;ff=ee;ee=sh256_add(dd,t1);dd=cc;cc=bb;bb=aa;aa=sh256_add(t1,t2)
        h[0]=sh256_add(h[0],aa);h[1]=sh256_add(h[1],bb);h[2]=sh256_add(h[2],cc);h[3]=sh256_add(h[3],dd);h[4]=sh256_add(h[4],ee);h[5]=sh256_add(h[5],ff);h[6]=sh256_add(h[6],gg);h[7]=sh256_add(h[7],hh)
    for i in range(8):for j in range(4):o[i*4+j]=UInt8((h[i]>>UInt(24-8*j))&255)
    return 32
