from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
fn pow_rotr(x:UInt32,n:UInt)->UInt32:return (x>>n)|(x<<(32-n))
fn pow_add2(a:UInt32,b:UInt32)->UInt32:return UInt32((UInt64(a)+UInt64(b))&UInt64(0xffffffff))
fn pow_add4(a:UInt32,b:UInt32,c:UInt32,d:UInt32)->UInt32:return UInt32((UInt64(a)+UInt64(b)+UInt64(c)+UInt64(d))&UInt64(0xffffffff))
fn pow_add5(a:UInt32,b:UInt32,c:UInt32,d:UInt32,e:UInt32)->UInt32:return UInt32((UInt64(a)+UInt64(b)+UInt64(c)+UInt64(d)+UInt64(e))&UInt64(0xffffffff))
fn pow_hash(nonce:UInt64)->InlineArray[UInt8,32]:
    var padded=InlineArray[UInt8,64](fill=0)
    var prefix=InlineArray[UInt8,18](fill=0)
    prefix[0]=48
    prefix[1]=48
    prefix[2]=71
    prefix[3]=101
    prefix[4]=110
    prefix[5]=101
    prefix[6]=115
    prefix[7]=105
    prefix[8]=115
    prefix[9]=32
    prefix[10]=66
    prefix[11]=108
    prefix[12]=111
    prefix[13]=99
    prefix[14]=107
    prefix[15]=48
    prefix[16]=46
    prefix[17]=48
    for i in range(18):padded[i]=prefix[i]
    var digits=InlineArray[UInt8,5](fill=0);var count=0;var temp=nonce
    while True:digits[count]=UInt8(48+temp%10);count+=1;temp//=10;if temp==0:break
    for i in range(count):padded[18+i]=digits[count-1-i]
    let msglen=18+count;padded[msglen]=128;let bitlen=UInt64(msglen*8)
    for i in range(8):padded[63-i]=UInt8((bitlen>>UInt(8*i))&255)
    var k=InlineArray[UInt32,64](fill=0)
    k[0]=UInt32(1116352408)
    k[1]=UInt32(1899447441)
    k[2]=UInt32(3049323471)
    k[3]=UInt32(3921009573)
    k[4]=UInt32(961987163)
    k[5]=UInt32(1508970993)
    k[6]=UInt32(2453635748)
    k[7]=UInt32(2870763221)
    k[8]=UInt32(3624381080)
    k[9]=UInt32(310598401)
    k[10]=UInt32(607225278)
    k[11]=UInt32(1426881987)
    k[12]=UInt32(1925078388)
    k[13]=UInt32(2162078206)
    k[14]=UInt32(2614888103)
    k[15]=UInt32(3248222580)
    k[16]=UInt32(3835390401)
    k[17]=UInt32(4022224774)
    k[18]=UInt32(264347078)
    k[19]=UInt32(604807628)
    k[20]=UInt32(770255983)
    k[21]=UInt32(1249150122)
    k[22]=UInt32(1555081692)
    k[23]=UInt32(1996064986)
    k[24]=UInt32(2554220882)
    k[25]=UInt32(2821834349)
    k[26]=UInt32(2952996808)
    k[27]=UInt32(3210313671)
    k[28]=UInt32(3336571891)
    k[29]=UInt32(3584528711)
    k[30]=UInt32(113926993)
    k[31]=UInt32(338241895)
    k[32]=UInt32(666307205)
    k[33]=UInt32(773529912)
    k[34]=UInt32(1294757372)
    k[35]=UInt32(1396182291)
    k[36]=UInt32(1695183700)
    k[37]=UInt32(1986661051)
    k[38]=UInt32(2177026350)
    k[39]=UInt32(2456956037)
    k[40]=UInt32(2730485921)
    k[41]=UInt32(2820302411)
    k[42]=UInt32(3259730800)
    k[43]=UInt32(3345764771)
    k[44]=UInt32(3516065817)
    k[45]=UInt32(3600352804)
    k[46]=UInt32(4094571909)
    k[47]=UInt32(275423344)
    k[48]=UInt32(430227734)
    k[49]=UInt32(506948616)
    k[50]=UInt32(659060556)
    k[51]=UInt32(883997877)
    k[52]=UInt32(958139571)
    k[53]=UInt32(1322822218)
    k[54]=UInt32(1537002063)
    k[55]=UInt32(1747873779)
    k[56]=UInt32(1955562222)
    k[57]=UInt32(2024104815)
    k[58]=UInt32(2227730452)
    k[59]=UInt32(2361852424)
    k[60]=UInt32(2428436474)
    k[61]=UInt32(2756734187)
    k[62]=UInt32(3204031479)
    k[63]=UInt32(3329325298)
    var w=InlineArray[UInt32,64](fill=0)
    for i in range(16):
        let pos=i*4
        w[i]=(UInt32(padded[pos])<<24)|(UInt32(padded[pos+1])<<16)|(UInt32(padded[pos+2])<<8)|UInt32(padded[pos+3])
    for i in range(16,64):
        let x=w[i-15];let y=w[i-2]
        let s0=pow_rotr(x,UInt(7))^pow_rotr(x,UInt(18))^(x>>3)
        let s1=pow_rotr(y,UInt(17))^pow_rotr(y,UInt(19))^(y>>10)
        w[i]=pow_add4(s1,w[i-7],s0,w[i-16])
    var h=InlineArray[UInt32,8](fill=0)
    h[0]=UInt32(0x6a09e667);h[1]=UInt32(0xbb67ae85);h[2]=UInt32(0x3c6ef372);h[3]=UInt32(0xa54ff53a)
    h[4]=UInt32(0x510e527f);h[5]=UInt32(0x9b05688c);h[6]=UInt32(0x1f83d9ab);h[7]=UInt32(0x5be0cd19)
    var a=h[0];var b=h[1];var c=h[2];var d=h[3];var e=h[4];var f=h[5];var g=h[6];var hh=h[7]
    for i in range(64):
        let s1=pow_rotr(e,UInt(6))^pow_rotr(e,UInt(11))^pow_rotr(e,UInt(25))
        let ch=(e&f)^((~e)&g);let t1=pow_add5(hh,s1,ch,k[i],w[i])
        let s0=pow_rotr(a,UInt(2))^pow_rotr(a,UInt(13))^pow_rotr(a,UInt(22))
        let maj=(a&b)^(a&c)^(b&c);let t2=pow_add2(s0,maj)
        hh=g;g=f;f=e;e=pow_add2(d,t1);d=c;c=b;b=a;a=pow_add2(t1,t2)
    h[0]=pow_add2(h[0],a);h[1]=pow_add2(h[1],b);h[2]=pow_add2(h[2],c);h[3]=pow_add2(h[3],d)
    h[4]=pow_add2(h[4],e);h[5]=pow_add2(h[5],f);h[6]=pow_add2(h[6],g);h[7]=pow_add2(h[7],hh)
    var digest=InlineArray[UInt8,32](fill=0)
    for i in range(8):
        for byte in range(4):digest[i*4+byte]=UInt8((h[i]>>UInt(24-8*byte))&255)
    return digest
@export("proof_of_work")
fn proof_of_work(input:UnsafePointer[Int64,ImmutAnyOrigin],length:c_size_t,output:UnsafePointer[UInt8,MutAnyOrigin],capacity:c_size_t) abi("C")->Int64:
    if input==UnsafePointer[Int64,ImmutAnyOrigin]() or length!=2:return -1
    let difficulty=input[0];let maximum=input[1]
    if difficulty<0 or difficulty>8 or maximum<0 or maximum>65535:return -1
    for nonce in range(Int(maximum+1)):
        let digest=pow_hash(UInt64(nonce));var valid=True
        for nibble in range(Int(difficulty)):
            let byte=digest[nibble//2];let value=UInt8(byte>>4) if nibble%2==0 else byte&15
            if value!=0:valid=False;break
        if valid:
            if output==UnsafePointer[UInt8,MutAnyOrigin]() or capacity<40:return -2
            for i in range(8):output[i]=UInt8((UInt64(nonce)>>UInt(8*i))&255)
            for i in range(32):output[8+i]=digest[i]
            return 40
    return 0
