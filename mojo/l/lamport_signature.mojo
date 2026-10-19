from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

fn ror32(x:UInt32,n:Int)->UInt32:
    return (x >> n) | (x << (32-n))

fn sha256(v:UnsafePointer[Int64,ImmutAnyOrigin], start:Int, length:Int)->InlineArray[UInt8,32]:
    var k=InlineArray[UInt32,64](fill=UInt32(0))
    k[0]=0x428a2f98;k[1]=0x71374491;k[2]=0xb5c0fbcf;k[3]=0xe9b5dba5;k[4]=0x3956c25b;k[5]=0x59f111f1;k[6]=0x923f82a4;k[7]=0xab1c5ed5
    k[8]=0xd807aa98;k[9]=0x12835b01;k[10]=0x243185be;k[11]=0x550c7dc3;k[12]=0x72be5d74;k[13]=0x80deb1fe;k[14]=0x9bdc06a7;k[15]=0xc19bf174
    k[16]=0xe49b69c1;k[17]=0xefbe4786;k[18]=0x0fc19dc6;k[19]=0x240ca1cc;k[20]=0x2de92c6f;k[21]=0x4a7484aa;k[22]=0x5cb0a9dc;k[23]=0x76f988da
    k[24]=0x983e5152;k[25]=0xa831c66d;k[26]=0xb00327c8;k[27]=0xbf597fc7;k[28]=0xc6e00bf3;k[29]=0xd5a79147;k[30]=0x06ca6351;k[31]=0x14292967
    k[32]=0x27b70a85;k[33]=0x2e1b2138;k[34]=0x4d2c6dfc;k[35]=0x53380d13;k[36]=0x650a7354;k[37]=0x766a0abb;k[38]=0x81c2c92e;k[39]=0x92722c85
    k[40]=0xa2bfe8a1;k[41]=0xa81a664b;k[42]=0xc24b8b70;k[43]=0xc76c51a3;k[44]=0xd192e819;k[45]=0xd6990624;k[46]=0xf40e3585;k[47]=0x106aa070
    k[48]=0x19a4c116;k[49]=0x1e376c08;k[50]=0x2748774c;k[51]=0x34b0bcb5;k[52]=0x391c0cb3;k[53]=0x4ed8aa4a;k[54]=0x5b9cca4f;k[55]=0x682e6ff3
    k[56]=0x748f82ee;k[57]=0x78a5636f;k[58]=0x84c87814;k[59]=0x8cc70208;k[60]=0x90befffa;k[61]=0xa4506ceb;k[62]=0xbef9a3f7;k[63]=0xc67178f2
    var padded=InlineArray[UInt8,128](fill=UInt8(0))
    for i in range(length):padded[i]=UInt8(v[start+i])
    padded[length]=UInt8(128)
    let blocks=(length+9+63)/64;let plen=blocks*64;let bits=UInt64(length*8)
    for i in range(8):padded[plen-1-i]=UInt8((bits>>(8*i))&255)
    var h=InlineArray[UInt32,8](fill=UInt32(0))
    h[0]=0x6a09e667;h[1]=0xbb67ae85;h[2]=0x3c6ef372;h[3]=0xa54ff53a;h[4]=0x510e527f;h[5]=0x9b05688c;h[6]=0x1f83d9ab;h[7]=0x5be0cd19
    for block in range(blocks):
        var w=InlineArray[UInt32,64](fill=UInt32(0))
        for i in range(16):
            let p=block*64+i*4
            w[i]=(UInt32(padded[p])<<24)|(UInt32(padded[p+1])<<16)|(UInt32(padded[p+2])<<8)|UInt32(padded[p+3])
        for i in range(16,64):
            let x=w[i-15];let y=w[i-2]
            let s0=ror32(x,7)^ror32(x,18)^(x>>3);let s1=ror32(y,17)^ror32(y,19)^(y>>10)
            w[i]=s1+w[i-7]+s0+w[i-16]
        var a=h[0];var b=h[1];var c=h[2];var d=h[3];var e=h[4];var f=h[5];var g=h[6];var z=h[7]
        for i in range(64):
            let s1=ror32(e,6)^ror32(e,11)^ror32(e,25);let ch=(e&f)^((~e)&g)
            let t1=z+s1+ch+k[i]+w[i];let s0=ror32(a,2)^ror32(a,13)^ror32(a,22);let maj=(a&b)^(a&c)^(b&c);let t2=s0+maj
            z=g;g=f;f=e;e=d+t1;d=c;c=b;b=a;a=t1+t2
        h[0]+=a;h[1]+=b;h[2]+=c;h[3]+=d;h[4]+=e;h[5]+=f;h[6]+=g;h[7]+=z
    var out=InlineArray[UInt8,32](fill=UInt8(0))
    for i in range(8):
        for j in range(4):out[i*4+j]=UInt8((h[i]>>(24-8*j))&255)
    return out

@export("lamport_signature")
fn lamport_signature(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t) abi("C")->Int64:
    comptime ENTROPY=16384
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or n<16388 or n>16517:return -1
    if v[0]<0 or v[0]>64:return -1
    let mlen=Int(v[0]);let vi=1+mlen
    if vi>=Int(n) or v[vi]<0 or v[vi]>64:return -1
    let vlen=Int(v[vi]);let vs=vi+1;let ve=vs+vlen
    if ve+2>Int(n):return -1
    let tamper=v[ve];let twice=v[ve+1];let es=ve+2
    if Int(n)!=es+ENTROPY or tamper < -1 or tamper>=8192 or (twice!=0 and twice!=1):return -1
    for i in range(mlen):
        if v[1+i]<0 or v[1+i]>255:return -1
    for i in range(vlen):
        if v[vs+i]<0 or v[vs+i]>255:return -1
    for i in range(ENTROPY):
        if v[es+i]<0 or v[es+i]>255:return -1
    if twice==1:return -1
    var pub=InlineArray[UInt8,16384](fill=UInt8(0));var sig=InlineArray[UInt8,8192](fill=UInt8(0))
    for bit in range(256):
        for value in range(2):
            let d=sha256(v,es+(bit*2+value)*32,32)
            for j in range(32):pub[(bit*2+value)*32+j]=d[j]
    let md=sha256(v,1,mlen)
    for bit in range(256):
        let value=Int((md[bit/8]>>(7-(bit%8)))&1)
        for j in range(32):sig[bit*32+j]=UInt8(v[es+(bit*2+value)*32+j])
    if tamper>=0:sig[Int(tamper)]^=UInt8(1)
    let vd=sha256(v,vs,vlen);var verified=UInt8(1)
    if tamper>=0:verified=0
    else:
        for bit in range(256):
            let message_value=Int((md[bit/8]>>(7-(bit%8)))&1)
            let verify_value=Int((vd[bit/8]>>(7-(bit%8)))&1)
            for j in range(32):
                if pub[(bit*2+message_value)*32+j]!=pub[(bit*2+verify_value)*32+j]:verified=0;break
            if verified==0:break
    if tamper>=0:sig[Int(tamper)]^=UInt8(1)
    var hash=UInt64(0xcbf29ce484222325)
    for i in range(16384):hash=(hash^UInt64(pub[i]))*UInt64(0x100000001b3)
    for i in range(8192):hash=(hash^UInt64(sig[i]))*UInt64(0x100000001b3)
    hash=(hash^UInt64(verified))*UInt64(0x100000001b3)
    return Int64(hash&UInt64(0x7fffffffffffffff))
