module merkle_tree

const max_input = 8192
const max_padded = 8256
const k = [64]u32{0x428a2f98,0x71374491,0xb5c0fbcf,0xe9b5dba5,0x3956c25b,0x59f111f1,0x923f82a4,0xab1c5ed5,0xd807aa98,0x12835b01,0x243185be,0x550c7dc3,0x72be5d74,0x80deb1fe,0x9bdc06a7,0xc19bf174,0xe49b69c1,0xefbe4786,0x0fc19dc6,0x240ca1cc,0x2de92c6f,0x4a7484aa,0x5cb0a9dc,0x76f988da,0x983e5152,0xa831c66d,0xb00327c8,0xbf597fc7,0xc6e00bf3,0xd5a79147,0x06ca6351,0x14292967,0x27b70a85,0x2e1b2138,0x4d2c6dfc,0x53380d13,0x650a7354,0x766a0abb,0x81c2c92e,0x92722c85,0xa2bfe8a1,0xa81a664b,0xc24b8b70,0xc76c51a3,0xd192e819,0xd6990624,0xf40e3585,0x106aa070,0x19a4c116,0x1e376c08,0x2748774c,0x34b0bcb5,0x391c0cb3,0x4ed8aa4a,0x5b9cca4f,0x682e6ff3,0x748f82ee,0x78a5636f,0x84c87814,0x8cc70208,0x90befffa,0xa4506ceb,0xbef9a3f7,0xc67178f2}
fn rotr(x u32, n u32) u32 { return (x >> n) | (x << (32 - n)) }
fn add32(a u32, b u32) u32 { return u32((u64(a) + u64(b)) & 0xffffffff) }

@[export: 'sha256']
pub fn sha256(input &i64, length usize, mut output &u8, capacity usize) i64 {
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


fn verify_signature(input &i64,height int,w int,msg int,leaf_index int,sig_pos int,pk_pos int,auth_pos int,root_pos int,l int) i64 {
 mut digest:=[32]u8{};mut current:=[32]u8{};if sha256(&input[3],usize(msg),mut digest[0],32)!=32{return 0}
 logw:=if w==4{2}else if w==16{4}else{8};len1:=if w==4{128}else if w==16{64}else{32};len2:=l-len1;mask:=w-1;mut digits:=[133]u8{};mut d:=0;mut checksum:=0
 for byte in 0..32 {for part in 0..8/logw {shift:=8-logw*(part+1);digits[d]=u8((int(digest[byte])>>shift)&mask);checksum+=mask-int(digits[d]);d++}}
 for i in 0..len2 {digits[len1+len2-1-i]=u8(checksum&mask);checksum >>= logw}
 mut chain:=[32]i64{};for i in 0..l {for j in 0..32{chain[j]=input[sig_pos+32*i+j]}for _ in 0..w-1-int(digits[i]){if sha256(&chain[0],32,mut current[0],32)!=32{return 0}for j in 0..32{chain[j]=i64(current[j])}}for j in 0..32{if u8(chain[j])!=u8(input[pk_pos+32*i+j]){return 0}}}
 if sha256(&input[pk_pos],usize(32*l),mut digest[0],32)!=32{return 0};mut pair:=[64]i64{};mut index:=leaf_index
 for level in 0..height {for j in 0..32 {left:=i64(digest[j]);right:=input[auth_pos+32*level+j];if index%2==0{pair[j]=left;pair[32+j]=right}else{pair[j]=right;pair[32+j]=left}}if sha256(&pair[0],64,mut digest[0],32)!=32{return 0}index >>= 1}
 for j in 0..32{if i64(digest[j])!=input[root_pos+j]{return 0}}return 1
}
@[export: 'merkle_signature_scheme']
pub fn merkle_signature_scheme(input &i64,length usize,mut output &u8,capacity usize) i64 {
 unsafe {
  if input==nil||length<4||length>8932{return -1};h0:=input[0];w0:=input[1];m0:=input[2];if h0<2||h0>10||(w0!=4&&w0!=16&&w0!=256)||m0<0||m0>64{return -1}
  height:=int(h0);w:=int(w0);msg:=int(m0);l:=if w==4{133}else if w==16{67}else{34};ip:=3+msg;expected:=4+msg+64*l+32*height+32;if int(length)!=expected{return -1}
  for i in 0..msg{if input[3+i]<0||input[3+i]>127{return -1}};idx:=input[ip];if idx<0||u64(idx)>=(u64(1)<<height){return -1};sig:=ip+1;pk:=sig+32*l;auth:=pk+32*l;root:=auth+32*height
  for i in sig..int(length){if input[i]<0||input[i]>255{return -1}};if output==nil||capacity<8{return -2};valid:=verify_signature(input,height,w,msg,int(idx),sig,pk,auth,root,l);for i in 0..8{output[i]=0};output[0]=u8(valid);return 8
 }
}
