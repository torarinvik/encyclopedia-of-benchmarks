module time_based_one_time_password_algorithm

const max_key = 64
const max_words = 67

fn rol(x u32, n u32) u32 { return (x << n) | (x >> (32 - n)) }
fn add32(a u32, b u32) u32 { return u32((u64(a) + u64(b)) & 0xffffffff) }

fn compress(mut h & [5]u32, block [64]u8) {
  mut w := [80]u32{}
  for i in 0 .. 16 { j:=i*4;w[i]=(u32(block[j])<<24)|(u32(block[j+1])<<16)|(u32(block[j+2])<<8)|u32(block[j+3]) }
  for i in 16 .. 80 { w[i]=rol(w[i-3]^w[i-8]^w[i-14]^w[i-16],1) }
  mut a:=h[0];mut b:=h[1];mut c:=h[2];mut d:=h[3];mut e:=h[4]
  for i in 0 .. 80 {
    mut f:=u32(0);mut k:=u32(0)
    if i<20 { f=(b&c)|(~b&d);k=0x5a827999 } else if i<40 { f=b^c^d;k=0x6ed9eba1 } else if i<60 { f=(b&c)|(b&d)|(c&d);k=0x8f1bbcdc } else { f=b^c^d;k=0xca62c1d6 }
    t:=add32(add32(add32(add32(rol(a,5),f),e),k),w[i]);e=d;d=c;c=rol(b,30);b=a;a=t
  }
  h[0]=add32(h[0],a);h[1]=add32(h[1],b);h[2]=add32(h[2],c);h[3]=add32(h[3],d);h[4]=add32(h[4],e)
}

fn initial() [5]u32 { return [5]u32{0x67452301,0xefcdab89,0x98badcfe,0x10325476,0xc3d2e1f0} }
fn serialize(h [5]u32, mut out & [20]u8) { for i in 0 .. 5 { for b in 0 .. 4 { out[i*4+b]=u8((h[i]>>(24-8*b))&255) } } }

fn compute(input &i64, key_len int, mut output [6]u8) {
  unsafe {
    mut key:=[64]u8{};mut block:=[64]u8{};mut inner:=[20]u8{}
    for i in 0 .. key_len { key[i]=u8(input[i+1]) }
    for i in 0 .. 64 { block[i]=key[i]^0x36 }
    mut h:=initial();compress(mut h,block);block=[64]u8{}
    counter:=u64(input[key_len+1])/30
    for i in 0 .. 8 { block[i]=u8((counter>>(56-8*i))&255) }
    block[8]=0x80;block[62]=2;block[63]=0x40;compress(mut h,block);serialize(h,mut inner)
    for i in 0 .. 64 { block[i]=key[i]^0x5c }
    h=initial();compress(mut h,block);block=[64]u8{}
    for i in 0 .. 20 { block[i]=inner[i] }
    block[20]=0x80;block[62]=2;block[63]=0xa0;compress(mut h,block);serialize(h,mut inner)
    offset:=int(inner[19]&15)
    mut binary:=(u32(inner[offset])<<24)|(u32(inner[offset+1])<<16)|(u32(inner[offset+2])<<8)|u32(inner[offset+3]);binary&=0x7fffffff
    mut value:=binary%1000000
    for i:=5; i>=0; i-- { output[i]=u8(48+value%10);value/=10 }
  }
}

@[export: 'time_based_one_time_password_algorithm']
pub fn time_based_one_time_password_algorithm(input &i64, length usize, mut output &u8, capacity usize) i64 {
  if length<3 || length>max_words { return -1 }
  unsafe {
    if input==nil { return -1 }
    key_word:=input[0]
    if key_word<16 || key_word>max_key || length!=usize(key_word+2) { return -1 }
    key_len:=int(key_word)
    for i in 0 .. key_len { if input[i+1]<0 || input[i+1]>255 { return -1 } }
    if input[key_len+1]<0 { return -1 }
    mut staged:=[6]u8{};compute(input,key_len,mut staged)
    if output==nil || capacity<6 { return -2 }
    for i in 0 .. 6 { output[i]=staged[i] }
    return 6
  }
}
