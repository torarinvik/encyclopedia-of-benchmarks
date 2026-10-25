package mibench_security_sha0

import "core:c"

INVALID_RESULT :: i64(-1)
OUTPUT_ERROR :: i64(-2)
MAX_MESSAGE_BYTES :: 55

rol32 :: proc "contextless" (value: u32, shift: u32) -> u32 { return (value << shift) | (value >> (32-shift)) }
add32 :: proc "contextless" (left, right: u32) -> u32 { return u32((u64(left)+u64(right)) & 0xffff_ffff) }

transform_sha0 :: proc "contextless" (block: [^]u8, state: [^]u32) {
    words: [80]u32
    for i := 0; i < 16; i += 1 { p:=i*4; words[i]=(u32(block[p])<<24)|(u32(block[p+1])<<16)|(u32(block[p+2])<<8)|u32(block[p+3]) }
    for i := 16; i < 80; i += 1 { words[i]=words[i-3]^words[i-8]^words[i-14]^words[i-16] }
    a,b,cc,d,e:=state[0],state[1],state[2],state[3],state[4]
    for i := 0; i < 80; i += 1 {
        f,k: u32
        if i<20 { f=(b&cc)|(^b&d);k=0x5A827999 }
        else if i<40 { f=b^cc^d;k=0x6ED9EBA1 }
        else if i<60 { f=(b&cc)|(b&d)|(cc&d);k=0x8F1BBCDC }
        else { f=b^cc^d;k=0xCA62C1D6 }
        temp:=add32(add32(add32(add32(rol32(a,5),f),e),words[i]),k)
        e=d;d=cc;cc=rol32(b,30);b=a;a=temp
    }
    state[0]=add32(state[0],a);state[1]=add32(state[1],b);state[2]=add32(state[2],cc)
    state[3]=add32(state[3],d);state[4]=add32(state[4],e)
}

@(export)
mibench_security_sha0 :: proc "c" (input: [^]i64, input_length: c.size_t,
        output: [^]u8, output_capacity: c.size_t) -> i64 {
    if input==nil || input_length<1 || input_length>MAX_MESSAGE_BYTES+2 do return INVALID_RESULT
    message_length:=input[0]
    if message_length<0 || message_length>MAX_MESSAGE_BYTES || input_length!=c.size_t(message_length)+1 do return INVALID_RESULT
    for i := c.size_t(1); i<input_length; i+=1 { if input[i]<0 || input[i]>255 do return INVALID_RESULT }
    block: [64]u8
    for i := 0; i<64; i+=1 { block[i]=0 }
    for i := i64(0); i<message_length; i+=1 { block[i]=u8(input[i+1]) }
    block[message_length]=0x80
    bit_length:=u64(message_length)*8
    for i := u64(0); i<8; i+=1 { block[63-i]=u8((bit_length>>(8*i))&255) }
    state: [5]u32={0x67452301,0xEFCDAB89,0x98BADCFE,0x10325476,0xC3D2E1F0}
    transform_sha0(&block[0],&state[0])
    if output==nil || output_capacity<20 do return OUTPUT_ERROR
    for i := 0; i<5; i+=1 { for j := 0; j<4; j+=1 { output[i*4+j]=u8((state[i]>>(24-8*j))&255) } }
    return 20
}
