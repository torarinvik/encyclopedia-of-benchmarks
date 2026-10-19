from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
fn sha2_r32(x:UInt32,n:Int)->UInt32:return (x>>UInt(n))|(x<<UInt(32-n))
fn sha2_r64(x:UInt64,n:Int)->UInt64:return (x>>UInt(n))|(x<<UInt(64-n))
fn sha2_c32(st:UnsafePointer[UInt32,MutAnyOrigin],msg:UnsafePointer[UInt8,MutAnyOrigin],off:Int,k:InlineArray[UInt32,64]):
    var w=InlineArray[UInt32,64]()
    for i in range(16):w[i]=(UInt32(msg[off+4*i])<<24)|(UInt32(msg[off+4*i+1])<<16)|(UInt32(msg[off+4*i+2])<<8)|UInt32(msg[off+4*i+3])
    for i in range(16,64):
        let x=w[i-15];let y=w[i-2];let s0=sha2_r32(x,7)^sha2_r32(x,18)^(x>>3);let s1=sha2_r32(y,17)^sha2_r32(y,19)^(y>>10);w[i]=w[i-16]+s0+w[i-7]+s1
    var a=st[0];var b=st[1];var c=st[2];var d=st[3];var e=st[4];var f=st[5];var g=st[6];var h=st[7]
    for i in range(64):
        let s1=sha2_r32(e,6)^sha2_r32(e,11)^sha2_r32(e,25);let ch=(e&f)^((~e)&g);let t1=h+s1+ch+k[i]+w[i];let s0=sha2_r32(a,2)^sha2_r32(a,13)^sha2_r32(a,22);let maj=(a&b)^(a&c)^(b&c);let t2=s0+maj
        h=g;g=f;f=e;e=d+t1;d=c;c=b;b=a;a=t1+t2
    for i in range(8):
        if i==0:st[i]+=a
        elif i==1:st[i]+=b
        elif i==2:st[i]+=c
        elif i==3:st[i]+=d
        elif i==4:st[i]+=e
        elif i==5:st[i]+=f
        elif i==6:st[i]+=g
        else:st[i]+=h
fn sha2_c64(st:UnsafePointer[UInt64,MutAnyOrigin],msg:UnsafePointer[UInt8,MutAnyOrigin],off:Int,k:InlineArray[UInt64,80]):
    var w=InlineArray[UInt64,80]()
    for i in range(16):
        var z:UInt64=0
        for j in range(8):z=(z<<8)|UInt64(msg[off+8*i+j])
        w[i]=z
    for i in range(16,80):
        let x=w[i-15];let y=w[i-2];let s0=sha2_r64(x,1)^sha2_r64(x,8)^(x>>7);let s1=sha2_r64(y,19)^sha2_r64(y,61)^(y>>6);w[i]=w[i-16]+s0+w[i-7]+s1
    var a=st[0];var b=st[1];var c=st[2];var d=st[3];var e=st[4];var f=st[5];var g=st[6];var h=st[7]
    for i in range(80):
        let s1=sha2_r64(e,14)^sha2_r64(e,18)^sha2_r64(e,41);let ch=(e&f)^((~e)&g);let t1=h+s1+ch+k[i]+w[i];let s0=sha2_r64(a,28)^sha2_r64(a,34)^sha2_r64(a,39);let maj=(a&b)^(a&c)^(b&c);let t2=s0+maj
        h=g;g=f;f=e;e=d+t1;d=c;c=b;b=a;a=t1+t2
    st[0]+=a;st[1]+=b;st[2]+=c;st[3]+=d;st[4]+=e;st[5]+=f;st[6]+=g;st[7]+=h
@export("sha2")
fn sha2(a:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t,o:UnsafePointer[UInt8,MutAnyOrigin],cap:c_size_t) abi("C")->Int64:
    if a==UnsafePointer[Int64,ImmutAnyOrigin]() or n<2 or n>4099:return -1
    let variant=a[0];let m=a[1];if variant<0 or variant>5 or m<0 or m>4096 or n!=c_size_t(m+2):return -1
    for i in range(Int(m)):if a[i+2]<0 or a[i+2]>255:return -1
    let lens=InlineArray[Int32,6](28,32,48,64,28,32);let digest=Int(lens[Int(variant)])
    if o==UnsafePointer[UInt8,MutAnyOrigin]() or cap<c_size_t(digest):return -2
    var msg=InlineArray[UInt8,4224]();for i in range(Int(m)):msg[i]=UInt8(a[i+2]);msg[Int(m)]=128
    if variant<2:
        var plen=Int(m)+1;while plen%64!=56:plen+=1;plen+=8;let bl=UInt64(m)*8
        for j in range(8):msg[plen-1-j]=UInt8((bl>>UInt(8*j))&255)
        let k=InlineArray[UInt32,64](0x428a2f98,0x71374491,0xb5c0fbcf,0xe9b5dba5,0x3956c25b,0x59f111f1,0x923f82a4,0xab1c5ed5,0xd807aa98,0x12835b01,0x243185be,0x550c7dc3,0x72be5d74,0x80deb1fe,0x9bdc06a7,0xc19bf174,0xe49b69c1,0xefbe4786,0x0fc19dc6,0x240ca1cc,0x2de92c6f,0x4a7484aa,0x5cb0a9dc,0x76f988da,0x983e5152,0xa831c66d,0xb00327c8,0xbf597fc7,0xc6e00bf3,0xd5a79147,0x06ca6351,0x14292967,0x27b70a85,0x2e1b2138,0x4d2c6dfc,0x53380d13,0x650a7354,0x766a0abb,0x81c2c92e,0x92722c85,0xa2bfe8a1,0xa81a664b,0xc24b8b70,0xc76c51a3,0xd192e819,0xd6990624,0xf40e3585,0x106aa070,0x19a4c116,0x1e376c08,0x2748774c,0x34b0bcb5,0x391c0cb3,0x4ed8aa4a,0x5b9cca4f,0x682e6ff3,0x748f82ee,0x78a5636f,0x84c87814,0x8cc70208,0x90befffa,0xa4506ceb,0xbef9a3f7,0xc67178f2)
        var h=InlineArray[UInt32,8](0xc1059ed8,0x367cd507,0x3070dd17,0xf70e5939,0xffc00b31,0x68581511,0x64f98fa7,0xbefa4fa4 if variant==0 else 0x6a09e667,0xbb67ae85,0x3c6ef372,0xa54ff53a,0x510e527f,0x9b05688c,0x1f83d9ab,0x5be0cd19)
        for off in range(0,plen,64):sha2_c32(h.unsafe_ptr(),msg.unsafe_ptr(),off,k)
        var p=0;for w in range(8):for j in range(4):if p<digest:o[p]=UInt8((h[w]>>UInt(24-8*j))&255);p+=1
    else:
        var plen=Int(m)+1;while plen%128!=112:plen+=1;plen+=16;let bl=UInt64(m)*8
        for j in range(8):msg[plen-1-j]=UInt8((bl>>UInt(8*j))&255)
        var h=InlineArray[UInt64,8]()
        let init=if variant==2 then InlineArray[UInt64,8](0xcbbb9d5dc1059ed8,0x629a292a367cd507,0x9159015a3070dd17,0x152fecd8f70e5939,0x67332667ffc00b31,0x8eb44a8768581511,0xdb0c2e0d64f98fa7,0x47b5481dbefa4fa4) else (if variant==3 then InlineArray[UInt64,8](0x6a09e667f3bcc908,0xbb67ae8584caa73b,0x3c6ef372fe94f82b,0xa54ff53a5f1d36f1,0x510e527fade682d1,0x9b05688c2b3e6c1f,0x1f83d9abfb41bd6b,0x5be0cd19137e2179) else (if variant==4 then InlineArray[UInt64,8](0x8c3d37c819544da2,0x73e1996689dcd4d6,0x1dfab7ae32ff9c82,0x679dd514582f9fcf,0x0f6d2b697bd44da8,0x77e36f7304c48942,0x3f9d85a86a1d36c8,0x1112e6ad91d692a1) else InlineArray[UInt64,8](0x22312194fc2bf72c,0x9f555fa3c84c64c2,0x2393b86b6f53b151,0x963877195940eabd,0x96283ee2a88effe3,0xbe5e1e2553863992,0x2b0199fc2c85b8aa,0x0eb72ddc81c52ca2)))
        h=init;let k=InlineArray[UInt64,80](0x428a2f98d728ae22,0x7137449123ef65cd,0xb5c0fbcfec4d3b2f,0xe9b5dba58189dbbc,0x3956c25bf348b538,0x59f111f1b605d019,0x923f82a4af194f9b,0xab1c5ed5da6d8118,0xd807aa98a3030242,0x12835b0145706fbe,0x243185be4ee4b28c,0x550c7dc3d5ffb4e2,0x72be5d74f27b896f,0x80deb1fe3b1696b1,0x9bdc06a725c71235,0xc19bf174cf692694,0xe49b69c19ef14ad2,0xefbe4786384f25e3,0x0fc19dc68b8cd5b5,0x240ca1cc77ac9c65,0x2de92c6f592b0275,0x4a7484aa6ea6e483,0x5cb0a9dcbd41fbd4,0x76f988da831153b5,0x983e5152ee66dfab,0xa831c66d2db43210,0xb00327c898fb213f,0xbf597fc7beef0ee4,0xc6e00bf33da88fc2,0xd5a79147930aa725,0x06ca6351e003826f,0x142929670a0e6e70,0x27b70a8546d22ffc,0x2e1b21385c26c926,0x4d2c6dfc5ac42aed,0x53380d139d95b3df,0x650a73548baf63de,0x766a0abb3c77b2a8,0x81c2c92e47edaee6,0x92722c851482353b,0xa2bfe8a14cf10364,0xa81a664bbc423001,0xc24b8b70d0f89791,0xc76c51a30654be30,0xd192e819d6ef5218,0xd69906245565a910,0xf40e35855771202a,0x106aa07032bbd1b8,0x19a4c116b8d2d0c8,0x1e376c085141ab53,0x2748774cdf8eeb99,0x34b0bcb5e19b48a8,0x391c0cb3c5c95a63,0x4ed8aa4ae3418acb,0x5b9cca4f7763e373,0x682e6ff3d6b2b8a3,0x748f82ee5defb2fc,0x78a5636f43172f60,0x84c87814a1f0ab72,0x8cc702081a6439ec,0x90befffa23631e28,0xa4506cebde82bde9,0xbef9a3f7b2c67915,0xc67178f2e372532b,0xca273eceea26619c,0xd186b8c721c0c207,0xeada7dd6cde0eb1e,0xf57d4f7fee6ed178,0x06f067aa72176fba,0x0a637dc5a2c898a6,0x113f9804bef90dae,0x1b710b35131c471b,0x28db77f523047d84,0x32caab7b40c72493,0x3c9ebe0a15c9bebc,0x431d67c49c100d4c,0x4cc5d4becb3e42b6,0x597f299cfc657e2a,0x5fcb6fab3ad6faec,0x6c44198c4a475817)
        for off in range(0,plen,128):sha2_c64(h.unsafe_ptr(),msg.unsafe_ptr(),off,k)
        var p=0;for w in range(8):for j in range(8):if p<digest:o[p]=UInt8((h[w]>>UInt(56-8*j))&255);p+=1
    return Int64(digest)
