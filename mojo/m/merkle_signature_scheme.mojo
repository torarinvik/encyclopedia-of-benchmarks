from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

fn mss_sha(data:InlineArray[Int64,4352],length:Int)->InlineArray[Int64,32]:
    let mask=UInt64(0xffffffff)
    var k=InlineArray[UInt64,64](0x428a2f98,0x71374491,0xb5c0fbcf,0xe9b5dba5,0x3956c25b,0x59f111f1,0x923f82a4,0xab1c5ed5,0xd807aa98,0x12835b01,0x243185be,0x550c7dc3,0x72be5d74,0x80deb1fe,0x9bdc06a7,0xc19bf174,0xe49b69c1,0xefbe4786,0x0fc19dc6,0x240ca1cc,0x2de92c6f,0x4a7484aa,0x5cb0a9dc,0x76f988da,0x983e5152,0xa831c66d,0xb00327c8,0xbf597fc7,0xc6e00bf3,0xd5a79147,0x06ca6351,0x14292967,0x27b70a85,0x2e1b2138,0x4d2c6dfc,0x53380d13,0x650a7354,0x766a0abb,0x81c2c92e,0x92722c85,0xa2bfe8a1,0xa81a664b,0xc24b8b70,0xc76c51a3,0xd192e819,0xd6990624,0xf40e3585,0x106aa070,0x19a4c116,0x1e376c08,0x2748774c,0x34b0bcb5,0x391c0cb3,0x4ed8aa4a,0x5b9cca4f,0x682e6ff3,0x748f82ee,0x78a5636f,0x84c87814,0x8cc70208,0x90befffa,0xa4506ceb,0xbef9a3f7,0xc67178f2)
    var pad=InlineArray[Int64,4352](fill=0)
    for i in range(length):pad[i]=data[i]
    pad[length]=128
    let blocks=(length+9+63)//64;let padded=blocks*64;let bits=UInt64(length*8)
    for i in range(8):pad[padded-1-i]=Int64((bits>>UInt64(i*8))&255)
    var h=InlineArray[UInt64,8](0x6a09e667,0xbb67ae85,0x3c6ef372,0xa54ff53a,0x510e527f,0x9b05688c,0x1f83d9ab,0x5be0cd19)
    for block in range(blocks):
        var w=InlineArray[UInt64,64](fill=0)
        for i in range(16):
            let p=block*64+i*4;w[i]=(UInt64(pad[p])<<24)|(UInt64(pad[p+1])<<16)|(UInt64(pad[p+2])<<8)|UInt64(pad[p+3])
        for i in range(16,64):
            let x=w[i-15];let y=w[i-2];let s0=(((x>>7)|(x<<25))&mask)^(((x>>18)|(x<<14))&mask)^(x>>3);let s1=(((y>>17)|(y<<15))&mask)^(((y>>19)|(y<<13))&mask)^(y>>10)
            w[i]=(s1+w[i-7]+s0+w[i-16])&mask
        var a=h[0];var b=h[1];var c=h[2];var d=h[3];var e=h[4];var f=h[5];var g=h[6];var hh=h[7]
        for i in range(64):
            let s1=(((e>>6)|(e<<26))&mask)^(((e>>11)|(e<<21))&mask)^(((e>>25)|(e<<7))&mask);let ch=(e&f)^((~e)&g);let t1=(hh+s1+ch+k[i]+w[i])&mask
            let s0=(((a>>2)|(a<<30))&mask)^(((a>>13)|(a<<19))&mask)^(((a>>22)|(a<<10))&mask);let maj=(a&b)^(a&c)^(b&c);let t2=(s0+maj)&mask
            hh=g;g=f;f=e;e=(d+t1)&mask;d=c;c=b;b=a;a=(t1+t2)&mask
        h[0]=(h[0]+a)&mask;h[1]=(h[1]+b)&mask;h[2]=(h[2]+c)&mask;h[3]=(h[3]+d)&mask;h[4]=(h[4]+e)&mask;h[5]=(h[5]+f)&mask;h[6]=(h[6]+g)&mask;h[7]=(h[7]+hh)&mask
    var digest=InlineArray[Int64,32](fill=0)
    for i in range(8):
        for b in range(4):digest[i*4+b]=Int64((h[i]>>UInt64(24-8*b))&255)
    return digest

@export("merkle_signature_scheme")
fn merkle_signature_scheme(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t,out:UnsafePointer[UInt8,MutAnyOrigin],cap:c_size_t) abi("C")->Int64:
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or n<4 or n>8932:return -1
    let h=v[0];let wv=v[1];let msg=v[2]
    if h<2 or h>10 or (wv!=4 and wv!=16 and wv!=256) or msg<0 or msg>64:return -1
    let height=Int(h);let w=Int(wv);let ml=Int(msg)
    let l=if w==4:133 elif w==16:67 else:34
    let idxpos=3+ml;let expected=4+ml+64*l+32*height+32
    if Int(n)!=expected:return -1
    for i in range(ml):if v[3+i]<0 or v[3+i]>127:return -1
    let idx=v[idxpos]
    if idx<0 or UInt64(idx)>=(UInt64(1)<<UInt64(height)):return -1
    let sig=idxpos+1;let pk=sig+32*l;let auth=pk+32*l;let root=auth+32*height
    for i in range(sig,Int(n)):if v[i]<0 or v[i]>255:return -1
    if out==UnsafePointer[UInt8,MutAnyOrigin]() or cap<8:return -2
    var message=InlineArray[Int64,4352](fill=0)
    for i in range(ml):message[i]=v[3+i]
    let digest=mss_sha(message,ml)
    let logw=if w==4:2 elif w==16:4 else:8
    let len1=if w==4:128 elif w==16:64 else:32
    let len2=l-len1;let mask=w-1;var digits=InlineArray[Int64,133](fill=0);var pos=0;var checksum=0
    for byte in range(32):
        for part in range(8//logw):
            let shift=8-logw*(part+1);let digit=(Int(digest[byte])>>shift)&mask
            digits[pos]=Int64(digit);checksum+=mask-digit;pos+=1
    for i in range(len2):digits[len1+len2-1-i]=Int64(checksum&mask);checksum>>=logw
    var valid=True
    for chain_index in range(l):
        var chain=InlineArray[Int64,4352](fill=0)
        for j in range(32):chain[j]=v[sig+32*chain_index+j]
        for _ in range(w-1-Int(digits[chain_index])):
            let d=mss_sha(chain,32)
            for j in range(32):chain[j]=d[j]
        for j in range(32):if chain[j]!=v[pk+32*chain_index+j]:valid=False
    var public_bytes=InlineArray[Int64,4352](fill=0)
    for i in range(32*l):public_bytes[i]=v[pk+i]
    var node=mss_sha(public_bytes,32*l);var leaf=idx
    for level in range(height):
        var pair=InlineArray[Int64,4352](fill=0)
        for j in range(32):
            let sibling=v[auth+32*level+j]
            if leaf%2==0:pair[j]=node[j];pair[32+j]=sibling
            else:pair[j]=sibling;pair[32+j]=node[j]
        node=mss_sha(pair,64);leaf>>=1
    for j in range(32):if node[j]!=v[root+j]:valid=False
    for i in range(8):out[i]=0
    if valid:out[0]=1
    return 8
