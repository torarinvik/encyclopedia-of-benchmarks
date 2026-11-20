package time_based_one_time_password_algorithm

import "core:c"

MAX_KEY :: 64
MAX_WORDS :: 67

rol :: proc "contextless" (x: u32, n: u32) -> u32 { return (x << n) | (x >> (32-n)) }
add32 :: proc "contextless" (a: u32, b: u32) -> u32 { return u32((u64(a)+u64(b)) & 0xffff_ffff) }

compress :: proc "contextless" (h: [^]u32, block: [^]u8) {
    w: [80]u32
    for i:=0; i<16; i+=1 { j:=i*4;w[i]=(u32(block[j])<<24)|(u32(block[j+1])<<16)|(u32(block[j+2])<<8)|u32(block[j+3]) }
    for i:=16; i<80; i+=1 { w[i]=rol(w[i-3]^w[i-8]^w[i-14]^w[i-16],1) }
    a,b,cc,d,e:=h[0],h[1],h[2],h[3],h[4]
    for i:=0; i<80; i+=1 {
        f,k:u32
        if i<20 { f=(b&cc)|(^b&d);k=0x5a827999 } else if i<40 { f=b^cc^d;k=0x6ed9eba1 } else if i<60 { f=(b&cc)|(b&d)|(cc&d);k=0x8f1bbcdc } else { f=b^cc^d;k=0xca62c1d6 }
        t:=add32(add32(add32(add32(rol(a,5),f),e),k),w[i]);e=d;d=cc;cc=rol(b,30);b=a;a=t
    }
    h[0]=add32(h[0],a);h[1]=add32(h[1],b);h[2]=add32(h[2],cc);h[3]=add32(h[3],d);h[4]=add32(h[4],e)
}

initial :: proc "contextless" () -> [5]u32 { return [5]u32{0x67452301,0xefcdab89,0x98badcfe,0x10325476,0xc3d2e1f0} }
serialize :: proc "contextless" (h: [^]u32, out: [^]u8) { for i:=0; i<5; i+=1 { for j:=0; j<4; j+=1 { out[i*4+j]=u8((h[i]>>(24-8*j))&255) } } }

compute :: proc "contextless" (input: [^]i64, key_len: int, out: ^[6]u8) {
    key: [64]u8
    block: [64]u8
    inner: [20]u8
    for i:=0; i<64; i+=1 { key[i]=0;block[i]=0 }
    for i:=0; i<key_len; i+=1 { key[i]=u8(input[i+1]) }
    for i:=0; i<64; i+=1 { block[i]=key[i]^0x36 }
    h:=initial();compress(&h[0],&block[0]);for i:=0; i<64; i+=1 { block[i]=0 }
    counter:=u64(input[key_len+1])/30
    for i:=0; i<8; i+=1 { block[i]=u8((counter>>(56-8*i))&255) }
    block[8]=0x80;block[62]=2;block[63]=0x40;compress(&h[0],&block[0]);serialize(&h[0],&inner[0])
    for i:=0; i<64; i+=1 { block[i]=key[i]^0x5c }
    h=initial();compress(&h[0],&block[0]);for i:=0; i<64; i+=1 { block[i]=0 }
    for i:=0; i<20; i+=1 { block[i]=inner[i] }
    block[20]=0x80;block[62]=2;block[63]=0xa0;compress(&h[0],&block[0]);serialize(&h[0],&inner[0])
    off:=int(inner[19]&15);binary:=(u32(inner[off])<<24)|(u32(inner[off+1])<<16)|(u32(inner[off+2])<<8)|u32(inner[off+3]);binary&=0x7fff_ffff
    value:=binary%1_000_000
    for i:=5; i>=0; i-=1 { out[i]=u8(48+value%10);value/=10 }
}

@(export)
time_based_one_time_password_algorithm :: proc "c" (input: [^]i64, length: c.size_t, output: [^]u8, capacity: c.size_t) -> i64 {
    if input==nil || length<3 || length>MAX_WORDS do return -1
    key_word:=input[0]
    if key_word<16 || key_word>MAX_KEY || length!=c.size_t(key_word+2) do return -1
    key_len:=int(key_word)
    for i:=0; i<key_len; i+=1 { if input[i+1]<0 || input[i+1]>255 do return -1 }
    if input[key_len+1]<0 do return -1
    staged:=[6]u8{}
    compute(input,key_len,&staged)
    if output==nil || capacity<6 do return -2
    for i:=0; i<6; i+=1 { output[i]=staged[i] }
    return 6
}
