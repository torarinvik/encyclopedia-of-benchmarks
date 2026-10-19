from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
fn sha1_add(a:UInt32,b:UInt32)->UInt32:return UInt32((UInt64(a)+UInt64(b))&0xffffffff)
@export("sha1")
fn sha1(a:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t,o:UnsafePointer[UInt8,MutAnyOrigin],cap:c_size_t) abi("C")->Int64:
    if n>4096 or (n>0 and a==UnsafePointer[Int64,ImmutAnyOrigin]()):return -1
    for i in range(Int(n)):if a[i]<0 or a[i]>255:return -1
    if o==UnsafePointer[UInt8,MutAnyOrigin]() or cap<20:return -2
    let padded=((Int(n)+9+63)/64)*64;var msg=InlineArray[UInt8,4224]()
    for i in range(Int(n)):msg[i]=UInt8(a[i])
    msg[Int(n)]=128;let bitlen=UInt64(n)*8
    for j in range(8):msg[padded-1-j]=UInt8((bitlen>>UInt(8*j))&255)
    var h=InlineArray[UInt32,5](0x67452301,0xefcdab89,0x98badcfe,0x10325476,0xc3d2e1f0)
    for off in range(0,padded,64):
        var w=InlineArray[UInt32,80]()
        for i in range(16):w[i]=(UInt32(msg[off+4*i])<<24)|(UInt32(msg[off+4*i+1])<<16)|(UInt32(msg[off+4*i+2])<<8)|UInt32(msg[off+4*i+3])
        for i in range(16,80):let v=w[i-3]^w[i-8]^w[i-14]^w[i-16];w[i]=(v<<1)|(v>>31)
        var aa=h[0];var bb=h[1];var cc=h[2];var dd=h[3];var ee=h[4]
        for i in range(80):
            var f:UInt32=0;var k:UInt32=0
            if i<20:f=(bb&cc)|((~bb)&dd);k=0x5a827999
            elif i<40:f=bb^cc^dd;k=0x6ed9eba1
            elif i<60:f=(bb&cc)|(bb&dd)|(cc&dd);k=0x8f1bbcdc
            else:f=bb^cc^dd;k=0xca62c1d6
            let rot=(aa<<5)|(aa>>27);let temp=sha1_add(sha1_add(sha1_add(sha1_add(rot,f),ee),k),w[i]);ee=dd;dd=cc;cc=(bb<<30)|(bb>>2);bb=aa;aa=temp
        h[0]=sha1_add(h[0],aa);h[1]=sha1_add(h[1],bb);h[2]=sha1_add(h[2],cc);h[3]=sha1_add(h[3],dd);h[4]=sha1_add(h[4],ee)
    for i in range(5):for j in range(4):o[i*4+j]=UInt8((h[i]>>UInt(24-8*j))&255)
    return 20
