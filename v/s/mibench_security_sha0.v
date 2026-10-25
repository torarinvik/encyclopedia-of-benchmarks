module mibench_security_sha0

const invalid_result = i64(-1)
const output_error = i64(-2)
const max_message_bytes = 55

fn rol32(value u32, shift u32) u32 { return (value << shift) | (value >> (32-shift)) }
fn add32(left u32, right u32) u32 { return u32((u64(left)+u64(right)) & 0xffffffff) }

fn transform_sha0(block [64]u8, mut state [5]u32) {
    mut words := [80]u32{}
    for i in 0 .. 16 {
        p := i*4
        words[i]=(u32(block[p])<<24)|(u32(block[p+1])<<16)|(u32(block[p+2])<<8)|u32(block[p+3])
    }
    for i in 16 .. 80 { words[i]=words[i-3]^words[i-8]^words[i-14]^words[i-16] }
    mut a:=state[0]; mut b:=state[1]; mut c:=state[2]; mut d:=state[3]; mut e:=state[4]
    for i in 0 .. 80 {
        mut f:=u32(0); mut k:=u32(0)
        if i<20 { f=(b&c)|((~b)&d);k=0x5A827999 }
        else if i<40 { f=b^c^d;k=0x6ED9EBA1 }
        else if i<60 { f=(b&c)|(b&d)|(c&d);k=0x8F1BBCDC }
        else { f=b^c^d;k=0xCA62C1D6 }
        temp:=add32(add32(add32(add32(rol32(a,5),f),e),words[i]),k)
        e=d;d=c;c=rol32(b,30);b=a;a=temp
    }
    state[0]=add32(state[0],a);state[1]=add32(state[1],b);state[2]=add32(state[2],c)
    state[3]=add32(state[3],d);state[4]=add32(state[4],e)
}

@[export: 'mibench_security_sha0']
pub fn mibench_security_sha0(input &i64, input_length usize, mut output &u8, output_capacity usize) i64 {
    if unsafe { input == nil } || input_length < 1 || input_length > max_message_bytes+2 { return invalid_result }
    message_length:=unsafe { input[0] }
    if message_length<0 || message_length>max_message_bytes || input_length!=usize(message_length+1) { return invalid_result }
    unsafe { for i in 1 .. input_length { if input[i]<0 || input[i]>255 { return invalid_result } } }
    mut block:=[64]u8{}
    unsafe { for i in 0 .. int(message_length) { block[i]=u8(input[i+1]) } }
    block[int(message_length)]=0x80
    bit_length:=u64(message_length)*8
    for i in 0 .. 8 { block[63-i]=u8((bit_length>>(8*i))&255) }
    mut state:=[5]u32{0x67452301,0xEFCDAB89,0x98BADCFE,0x10325476,0xC3D2E1F0}
    transform_sha0(block,mut state)
    if unsafe { output == nil } || output_capacity<20 { return output_error }
    unsafe { for i in 0 .. 5 { for j in 0 .. 4 { output[i*4+j]=u8((state[i]>>(24-8*j))&255) } } }
    return 20
}
