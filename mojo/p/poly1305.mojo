from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

fn poly_load4(a:UInt64,b:UInt64,c:UInt64,d:UInt64)->UInt64:
    return a|(b<<8)|(c<<16)|(d<<24)

@export("poly1305")
fn poly1305(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t,out:UnsafePointer[UInt8,MutAnyOrigin],cap:c_size_t) abi("C")->Int64:
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or n<33 or n>98:return -1
    let ml=v[0]
    if ml<0 or ml>64 or n!=c_size_t(33+ml):return -1
    for i in range(1,Int(n)):if v[i]<0 or v[i]>255:return -1
    if out==UnsafePointer[UInt8,MutAnyOrigin]() or cap<16:return -2
    var key=InlineArray[UInt64,32](fill=0)
    var msg=InlineArray[UInt64,64](fill=0)
    for i in range(32):key[i]=UInt64(v[i+1])
    for i in range(Int(ml)):msg[i]=UInt64(v[33+i])
    let mask=UInt64(0x3ffffff)
    let r0=poly_load4(key[0],key[1],key[2],key[3])&mask
    let r1=(poly_load4(key[3],key[4],key[5],key[6])>>2)&UInt64(0x3ffff03)
    let r2=(poly_load4(key[6],key[7],key[8],key[9])>>4)&UInt64(0x3ffc0ff)
    let r3=(poly_load4(key[9],key[10],key[11],key[12])>>6)&UInt64(0x3f03fff)
    let r4=(poly_load4(key[12],key[13],key[14],key[15])>>8)&UInt64(0x00fffff)
    let s1=r1*5;let s2=r2*5;let s3=r3*5;let s4=r4*5
    var h0=UInt64(0);var h1=UInt64(0);var h2=UInt64(0);var h3=UInt64(0);var h4=UInt64(0)
    var offset=0
    while offset<Int(ml):
        var block=InlineArray[UInt64,16](fill=0)
        let blen=min(16,Int(ml)-offset)
        for i in range(blen):block[i]=msg[offset+i]
        var high=UInt64(1<<24)
        if blen<16:block[blen]=1;high=0
        h0+=poly_load4(block[0],block[1],block[2],block[3])&mask
        h1+=(poly_load4(block[3],block[4],block[5],block[6])>>2)&mask
        h2+=(poly_load4(block[6],block[7],block[8],block[9])>>4)&mask
        h3+=(poly_load4(block[9],block[10],block[11],block[12])>>6)&mask
        h4+=(poly_load4(block[12],block[13],block[14],block[15])>>8)+high
        let d0=h0*r0+h1*s4+h2*s3+h3*s2+h4*s1
        let d1=h0*r1+h1*r0+h2*s4+h3*s3+h4*s2
        let d2=h0*r2+h1*r1+h2*r0+h3*s4+h4*s3
        let d3=h0*r3+h1*r2+h2*r1+h3*r0+h4*s4
        let d4=h0*r4+h1*r3+h2*r2+h3*r1+h4*r0
        var carry=d0>>26;h0=d0&mask
        var q=d1+carry;carry=q>>26;h1=q&mask
        q=d2+carry;carry=q>>26;h2=q&mask
        q=d3+carry;carry=q>>26;h3=q&mask
        q=d4+carry;carry=q>>26;h4=q&mask
        h0+=carry*5;carry=h0>>26;h0&=mask;h1+=carry
        offset+=blen
    for _ in range(3):
        var carry=h0>>26;h0&=mask;h1+=carry
        carry=h1>>26;h1&=mask;h2+=carry
        carry=h2>>26;h2&=mask;h3+=carry
        carry=h3>>26;h3&=mask;h4+=carry
        carry=h4>>26;h4&=mask;h0+=carry*5
        carry=h0>>26;h0&=mask;h1+=carry
    if h4==mask and h3==mask and h2==mask and h1==mask and h0>=mask-4:
        h0-=mask-4;h1=0;h2=0;h3=0;h4=0
    var f0=((h0|(h1<<26))&UInt64(0xffffffff))+poly_load4(key[16],key[17],key[18],key[19])
    var f1=((h1>>6|(h2<<20))&UInt64(0xffffffff))+poly_load4(key[20],key[21],key[22],key[23])+(f0>>32)
    var f2=((h2>>12|(h3<<14))&UInt64(0xffffffff))+poly_load4(key[24],key[25],key[26],key[27])+(f1>>32)
    var f3=((h3>>18|(h4<<8))&UInt64(0xffffffff))+poly_load4(key[28],key[29],key[30],key[31])+(f2>>32)
    for i in range(4):out[i]=UInt8((f0>>(8*i))&255);out[4+i]=UInt8((f1>>(8*i))&255);out[8+i]=UInt8((f2>>(8*i))&255);out[12+i]=UInt8((f3>>(8*i))&255)
    return 16
