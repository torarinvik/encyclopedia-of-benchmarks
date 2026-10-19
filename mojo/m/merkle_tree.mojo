from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

fn mt_sha(data:InlineArray[Int64,128],length:Int)->InlineArray[Int64,32]:
    let mask=UInt64(0xffffffff)
    var k=InlineArray[UInt64,64](0x428a2f98,0x71374491,0xb5c0fbcf,0xe9b5dba5,0x3956c25b,0x59f111f1,0x923f82a4,0xab1c5ed5,0xd807aa98,0x12835b01,0x243185be,0x550c7dc3,0x72be5d74,0x80deb1fe,0x9bdc06a7,0xc19bf174,0xe49b69c1,0xefbe4786,0x0fc19dc6,0x240ca1cc,0x2de92c6f,0x4a7484aa,0x5cb0a9dc,0x76f988da,0x983e5152,0xa831c66d,0xb00327c8,0xbf597fc7,0xc6e00bf3,0xd5a79147,0x06ca6351,0x14292967,0x27b70a85,0x2e1b2138,0x4d2c6dfc,0x53380d13,0x650a7354,0x766a0abb,0x81c2c92e,0x92722c85,0xa2bfe8a1,0xa81a664b,0xc24b8b70,0xc76c51a3,0xd192e819,0xd6990624,0xf40e3585,0x106aa070,0x19a4c116,0x1e376c08,0x2748774c,0x34b0bcb5,0x391c0cb3,0x4ed8aa4a,0x5b9cca4f,0x682e6ff3,0x748f82ee,0x78a5636f,0x84c87814,0x8cc70208,0x90befffa,0xa4506ceb,0xbef9a3f7,0xc67178f2)
    var pad=InlineArray[Int64,192](fill=0)
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
fn mt_hex(n:Int)->Int64:
    return Int64(48+n) if n<10 else Int64(87+n)
fn mt_write_hex(out:UnsafePointer[UInt8,MutAnyOrigin],pos:Int,d:InlineArray[Int64,32]):
    for i in range(32):out[pos+2*i]=UInt8(mt_hex(Int(d[i]>>4)));out[pos+2*i+1]=UInt8(mt_hex(Int(d[i]&15)))
@export("merkle_tree")
fn merkle_tree(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t,out:UnsafePointer[UInt8,MutAnyOrigin],cap:c_size_t) abi("C")->Int64:
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or n<1 or n>1041:return -1
    let count=v[0]
    if count<1 or count>16:return -1
    var level=InlineArray[Int64,1024](fill=0);var pos=1
    for leaf in range(Int(count)):
        if pos>=Int(n):return -1
        let len=v[pos];pos+=1
        if len<0 or len>64 or pos+Int(len)>Int(n):return -1
        var bytes=InlineArray[Int64,128](fill=0)
        for i in range(Int(len)):
            if v[pos+i]<0 or v[pos+i]>127:return -1
            bytes[i]=v[pos+i]
        let d=mt_sha(bytes,Int(len));mt_write_hex_dummy(mut level,leaf*64,d);pos+=Int(len)
    if pos!=Int(n):return -1
    var nodes=Int(count)
    while nodes>1:
        var next=0
        for i in range(0,nodes,2):
            let r=if i+1<nodes:i+1 else:i;var pair=InlineArray[Int64,128](fill=0)
            for j in range(64):pair[j]=level[i*64+j];pair[64+j]=level[r*64+j]
            let d=mt_sha(pair,128);mt_write_hex_dummy(mut level,next*64,d);next+=1
        nodes=next
    if out==UnsafePointer[UInt8,MutAnyOrigin]() or cap<64:return -2
    for i in range(64):out[i]=UInt8(level[i])
    return 64
fn mt_write_hex_dummy(mut a:InlineArray[Int64,1024],pos:Int,d:InlineArray[Int64,32]):
    for i in range(32):a[pos+2*i]=mt_hex(Int(d[i]>>4));a[pos+2*i+1]=mt_hex(Int(d[i]&15))
