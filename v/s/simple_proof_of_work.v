module sha256

const max_input = 4096
const max_padded = 4160
const k = [64]u32{0x428a2f98,0x71374491,0xb5c0fbcf,0xe9b5dba5,0x3956c25b,0x59f111f1,0x923f82a4,0xab1c5ed5,0xd807aa98,0x12835b01,0x243185be,0x550c7dc3,0x72be5d74,0x80deb1fe,0x9bdc06a7,0xc19bf174,0xe49b69c1,0xefbe4786,0x0fc19dc6,0x240ca1cc,0x2de92c6f,0x4a7484aa,0x5cb0a9dc,0x76f988da,0x983e5152,0xa831c66d,0xb00327c8,0xbf597fc7,0xc6e00bf3,0xd5a79147,0x06ca6351,0x14292967,0x27b70a85,0x2e1b2138,0x4d2c6dfc,0x53380d13,0x650a7354,0x766a0abb,0x81c2c92e,0x92722c85,0xa2bfe8a1,0xa81a664b,0xc24b8b70,0xc76c51a3,0xd192e819,0xd6990624,0xf40e3585,0x106aa070,0x19a4c116,0x1e376c08,0x2748774c,0x34b0bcb5,0x391c0cb3,0x4ed8aa4a,0x5b9cca4f,0x682e6ff3,0x748f82ee,0x78a5636f,0x84c87814,0x8cc70208,0x90befffa,0xa4506ceb,0xbef9a3f7,0xc67178f2}
fn rotr(x u32, n u32) u32 { return (x >> n) | (x << (32 - n)) }
fn add32(a u32, b u32) u32 { return u32((u64(a) + u64(b)) & 0xffffffff) }

fn proof_of_work_hash(input &i64, length usize, mut output &u8, capacity usize) i64 {
	if length > max_input { return -1 }
	unsafe {
		if length > 0 && input == nil { return -1 }
		for i in 0 .. int(length) { if input[i] < 0 || input[i] > 255 { return -1 } }
		mut padded := [max_padded]u8{}
		for i in 0 .. int(length) { padded[i] = u8(input[i]) }
		padded[length] = 0x80
		blocks := (length + 9 + 63) / 64
		padded_length := blocks * 64
		bit_length := u64(length) * 8
		for i in 0 .. 8 { padded[padded_length - 1 - i] = u8((bit_length >> (8 * i)) & 255) }
		mut h := [8]u32{0x6a09e667,0xbb67ae85,0x3c6ef372,0xa54ff53a,0x510e527f,0x9b05688c,0x1f83d9ab,0x5be0cd19}
		for block in 0 .. blocks {
			mut w := [64]u32{}
			for i in 0 .. 16 { p := block * 64 + i * 4; w[i] = (u32(padded[p]) << 24) | (u32(padded[p+1]) << 16) | (u32(padded[p+2]) << 8) | u32(padded[p+3]) }
			for i in 16 .. 64 { x := w[i-15]; y := w[i-2]; s0 := rotr(x,7) ^ rotr(x,18) ^ (x >> 3); s1 := rotr(y,17) ^ rotr(y,19) ^ (y >> 10); w[i] = add32(add32(add32(s1,w[i-7]),s0),w[i-16]) }
			mut a := h[0]; mut b := h[1]; mut c := h[2]; mut d := h[3]; mut e := h[4]; mut f := h[5]; mut g := h[6]; mut hh := h[7]
			for i in 0 .. 64 {
				s1 := rotr(e,6) ^ rotr(e,11) ^ rotr(e,25); ch := (e & f) ^ ((~e) & g)
				t1 := add32(add32(add32(add32(hh,s1),ch),k[i]),w[i])
				s0 := rotr(a,2) ^ rotr(a,13) ^ rotr(a,22); maj := (a & b) ^ (a & c) ^ (b & c); t2 := add32(s0,maj)
				hh=g;g=f;f=e;e=add32(d,t1);d=c;c=b;b=a;a=add32(t1,t2)
			}
			h[0]=add32(h[0],a);h[1]=add32(h[1],b);h[2]=add32(h[2],c);h[3]=add32(h[3],d);h[4]=add32(h[4],e);h[5]=add32(h[5],f);h[6]=add32(h[6],g);h[7]=add32(h[7],hh)
		}
		if output == nil || capacity < 32 { return -2 }
		for i in 0 .. 8 { for byte in 0 .. 4 { output[i*4+byte] = u8((h[i] >> (24 - 8 * byte)) & 255) } }
		return 32
	}
}


fn append_decimal(mut out &i64,start int,initial u64) int {mut p:=start;mut v:=initial;mut d:=[20]u8{};mut n:=0;for{d[n]=u8(`0`)+u8(v%10);n++;v/=10;if v==0{break}};for n>0{n--;unsafe{out[p]=i64(d[n])};p++};return p}
fn zero_prefix(d &u8,difficulty i64) bool {unsafe{for i in 0..int(difficulty){b:=d[i/2];x:=if i%2==0{b>>4}else{b&15};if x!=0{return false}}};return true}
@[export: 'simple_proof_of_work']
pub fn simple_proof_of_work(input &i64,length usize,mut output &u8,capacity usize)i64{
 if length<5||length>134{return -1};unsafe{if input==nil{return -1};block:=input[0];diff:=input[1];maxn:=input[2];tl:=input[3];pl:=input[4];if block<0||diff<0||diff>2||maxn<0||maxn>4096||tl<0||tl>64||pl<0||pl>64{return -1};if length!=5+usize(tl)+usize(pl){return -1};for i in 0..int(tl){if input[5+i]<0||input[5+i]>127{return -1}};for i in 0..int(pl){if input[5+int(tl)+i]<0||input[5+int(tl)+i]>127{return -1}};if output==nil||capacity<72{return -2};hex:='0123456789abcdef';mut nonce:=u64(0);for nonce<=u64(maxn){mut m:=[151]i64{};mut n:=append_decimal(&m[0],0,u64(block));for i in 0..int(tl){m[n]=input[5+i];n++};for i in 0..int(pl){m[n]=input[5+int(tl)+i];n++};n=append_decimal(&m[0],n,nonce);mut d:=[32]u8{};if proof_of_work_hash(&m[0],usize(n),&d[0],32)!=32{return -1};if zero_prefix(&d[0],diff){for i in 0..8{output[i]=u8((nonce>>(8*i))&255)};for i in 0..32{output[8+2*i]=hex[d[i]>>4];output[9+2*i]=hex[d[i]&15]};return 72};nonce++};return -3}}
