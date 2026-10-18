module sha2

const max_message_bytes = 4096
const max_parseable_input_length = 4099
const max_padded_bytes = 4224
const max_output_bytes = 64
const k32 = [64]u32{0x428a2f98,0x71374491,0xb5c0fbcf,0xe9b5dba5,0x3956c25b,0x59f111f1,0x923f82a4,0xab1c5ed5,0xd807aa98,0x12835b01,0x243185be,0x550c7dc3,0x72be5d74,0x80deb1fe,0x9bdc06a7,0xc19bf174,0xe49b69c1,0xefbe4786,0x0fc19dc6,0x240ca1cc,0x2de92c6f,0x4a7484aa,0x5cb0a9dc,0x76f988da,0x983e5152,0xa831c66d,0xb00327c8,0xbf597fc7,0xc6e00bf3,0xd5a79147,0x06ca6351,0x14292967,0x27b70a85,0x2e1b2138,0x4d2c6dfc,0x53380d13,0x650a7354,0x766a0abb,0x81c2c92e,0x92722c85,0xa2bfe8a1,0xa81a664b,0xc24b8b70,0xc76c51a3,0xd192e819,0xd6990624,0xf40e3585,0x106aa070,0x19a4c116,0x1e376c08,0x2748774c,0x34b0bcb5,0x391c0cb3,0x4ed8aa4a,0x5b9cca4f,0x682e6ff3,0x748f82ee,0x78a5636f,0x84c87814,0x8cc70208,0x90befffa,0xa4506ceb,0xbef9a3f7,0xc67178f2}
const k64 = [80]u64{
	u64(0x428a2f98d728ae22),u64(0x7137449123ef65cd),u64(0xb5c0fbcfec4d3b2f),u64(0xe9b5dba58189dbbc),u64(0x3956c25bf348b538),u64(0x59f111f1b605d019),u64(0x923f82a4af194f9b),u64(0xab1c5ed5da6d8118),
	u64(0xd807aa98a3030242),u64(0x12835b0145706fbe),u64(0x243185be4ee4b28c),u64(0x550c7dc3d5ffb4e2),u64(0x72be5d74f27b896f),u64(0x80deb1fe3b1696b1),u64(0x9bdc06a725c71235),u64(0xc19bf174cf692694),
	u64(0xe49b69c19ef14ad2),u64(0xefbe4786384f25e3),u64(0x0fc19dc68b8cd5b5),u64(0x240ca1cc77ac9c65),u64(0x2de92c6f592b0275),u64(0x4a7484aa6ea6e483),u64(0x5cb0a9dcbd41fbd4),u64(0x76f988da831153b5),
	u64(0x983e5152ee66dfab),u64(0xa831c66d2db43210),u64(0xb00327c898fb213f),u64(0xbf597fc7beef0ee4),u64(0xc6e00bf33da88fc2),u64(0xd5a79147930aa725),u64(0x06ca6351e003826f),u64(0x142929670a0e6e70),
	u64(0x27b70a8546d22ffc),u64(0x2e1b21385c26c926),u64(0x4d2c6dfc5ac42aed),u64(0x53380d139d95b3df),u64(0x650a73548baf63de),u64(0x766a0abb3c77b2a8),u64(0x81c2c92e47edaee6),u64(0x92722c851482353b),
	u64(0xa2bfe8a14cf10364),u64(0xa81a664bbc423001),u64(0xc24b8b70d0f89791),u64(0xc76c51a30654be30),u64(0xd192e819d6ef5218),u64(0xd69906245565a910),u64(0xf40e35855771202a),u64(0x106aa07032bbd1b8),
	u64(0x19a4c116b8d2d0c8),u64(0x1e376c085141ab53),u64(0x2748774cdf8eeb99),u64(0x34b0bcb5e19b48a8),u64(0x391c0cb3c5c95a63),u64(0x4ed8aa4ae3418acb),u64(0x5b9cca4f7763e373),u64(0x682e6ff3d6b2b8a3),
	u64(0x748f82ee5defb2fc),u64(0x78a5636f43172f60),u64(0x84c87814a1f0ab72),u64(0x8cc702081a6439ec),u64(0x90befffa23631e28),u64(0xa4506cebde82bde9),u64(0xbef9a3f7b2c67915),u64(0xc67178f2e372532b),
	u64(0xca273eceea26619c),u64(0xd186b8c721c0c207),u64(0xeada7dd6cde0eb1e),u64(0xf57d4f7fee6ed178),u64(0x06f067aa72176fba),u64(0x0a637dc5a2c898a6),u64(0x113f9804bef90dae),u64(0x1b710b35131c471b),
	u64(0x28db77f523047d84),u64(0x32caab7b40c72493),u64(0x3c9ebe0a15c9bebc),u64(0x431d67c49c100d4c),u64(0x4cc5d4becb3e42b6),u64(0x597f299cfc657e2a),u64(0x5fcb6fab3ad6faec),u64(0x6c44198c4a475817),
}
const h224 = [8]u32{0xc1059ed8,0x367cd507,0x3070dd17,0xf70e5939,0xffc00b31,0x68581511,0x64f98fa7,0xbefa4fa4}
const h256 = [8]u32{0x6a09e667,0xbb67ae85,0x3c6ef372,0xa54ff53a,0x510e527f,0x9b05688c,0x1f83d9ab,0x5be0cd19}
const h384 = [8]u64{u64(0xcbbb9d5dc1059ed8),u64(0x629a292a367cd507),u64(0x9159015a3070dd17),u64(0x152fecd8f70e5939),u64(0x67332667ffc00b31),u64(0x8eb44a8768581511),u64(0xdb0c2e0d64f98fa7),u64(0x47b5481dbefa4fa4)}
const h512 = [8]u64{u64(0x6a09e667f3bcc908),u64(0xbb67ae8584caa73b),u64(0x3c6ef372fe94f82b),u64(0xa54ff53a5f1d36f1),u64(0x510e527fade682d1),u64(0x9b05688c2b3e6c1f),u64(0x1f83d9abfb41bd6b),u64(0x5be0cd19137e2179)}
const h512_224 = [8]u64{u64(0x8c3d37c819544da2),u64(0x73e1996689dcd4d6),u64(0x1dfab7ae32ff9c82),u64(0x679dd514582f9fcf),u64(0x0f6d2b697bd44da8),u64(0x77e36f7304c48942),u64(0x3f9d85a86a1d36c8),u64(0x1112e6ad91d692a1)}
const h512_256 = [8]u64{u64(0x22312194fc2bf72c),u64(0x9f555fa3c84c64c2),u64(0x2393b86b6f53b151),u64(0x963877195940eabd),u64(0x96283ee2a88effe3),u64(0xbe5e1e2553863992),u64(0x2b0199fc2c85b8aa),u64(0x0eb72ddc81c52ca2)}

fn sha2_rotr32(x u32, n u32) u32 { return (x >> n) | (x << (32 - n)) }
fn sha2_rotr64(x u64, n u32) u64 { return (x >> n) | (x << (64 - n)) }
fn sha2_add32(a u32, b u32) u32 { return u32((u64(a) + u64(b)) & 0xffffffff) }
fn sha2_add64(a u64, b u64) u64 { return u64((u128(a) + u128(b)) & u128(0xffffffffffffffff)) }

fn sha2_compress32(mut state &u32, block &u8) {
	mut words := [64]u32{}
	for index in 0 .. 16 { p := index * 4; words[index] = (u32(block[p]) << 24) | (u32(block[p+1]) << 16) | (u32(block[p+2]) << 8) | u32(block[p+3]) }
	for index in 16 .. 64 { x := words[index-15]; y := words[index-2]; s0 := sha2_rotr32(x,7)^sha2_rotr32(x,18)^(x>>3); s1 := sha2_rotr32(y,17)^sha2_rotr32(y,19)^(y>>10); words[index] = sha2_add32(sha2_add32(sha2_add32(words[index-16],s0),words[index-7]),s1) }
	mut a:=state[0];mut b:=state[1];mut c:=state[2];mut d:=state[3];mut e:=state[4];mut f:=state[5];mut g:=state[6];mut h:=state[7]
	for index in 0 .. 64 { s1:=sha2_rotr32(e,6)^sha2_rotr32(e,11)^sha2_rotr32(e,25); ch:=(e&f)^((~e)&g); t1:=sha2_add32(sha2_add32(sha2_add32(sha2_add32(h,s1),ch),k32[index]),words[index]); s0:=sha2_rotr32(a,2)^sha2_rotr32(a,13)^sha2_rotr32(a,22); maj:=(a&b)^(a&c)^(b&c); t2:=sha2_add32(s0,maj); h=g;g=f;f=e;e=sha2_add32(d,t1);d=c;c=b;b=a;a=sha2_add32(t1,t2) }
	state[0]=sha2_add32(state[0],a);state[1]=sha2_add32(state[1],b);state[2]=sha2_add32(state[2],c);state[3]=sha2_add32(state[3],d);state[4]=sha2_add32(state[4],e);state[5]=sha2_add32(state[5],f);state[6]=sha2_add32(state[6],g);state[7]=sha2_add32(state[7],h)
}

fn sha2_compress64(mut state &u64, block &u8) {
	mut words := [80]u64{}
	for index in 0 .. 16 { mut value:=u64(0);for byte in 0 .. 8 { value=(value<<8)|u64(block[index*8+byte]) };words[index]=value }
	for index in 16 .. 80 { x:=words[index-15];y:=words[index-2];s0:=sha2_rotr64(x,1)^sha2_rotr64(x,8)^(x>>7);s1:=sha2_rotr64(y,19)^sha2_rotr64(y,61)^(y>>6);words[index]=sha2_add64(sha2_add64(sha2_add64(words[index-16],s0),words[index-7]),s1) }
	mut a:=state[0];mut b:=state[1];mut c:=state[2];mut d:=state[3];mut e:=state[4];mut f:=state[5];mut g:=state[6];mut h:=state[7]
	for index in 0 .. 80 { s1:=sha2_rotr64(e,14)^sha2_rotr64(e,18)^sha2_rotr64(e,41);ch:=(e&f)^((~e)&g);t1:=sha2_add64(sha2_add64(sha2_add64(sha2_add64(h,s1),ch),k64[index]),words[index]);s0:=sha2_rotr64(a,28)^sha2_rotr64(a,34)^sha2_rotr64(a,39);maj:=(a&b)^(a&c)^(b&c);t2:=sha2_add64(s0,maj);h=g;g=f;f=e;e=sha2_add64(d,t1);d=c;c=b;b=a;a=sha2_add64(t1,t2) }
	state[0]=sha2_add64(state[0],a);state[1]=sha2_add64(state[1],b);state[2]=sha2_add64(state[2],c);state[3]=sha2_add64(state[3],d);state[4]=sha2_add64(state[4],e);state[5]=sha2_add64(state[5],f);state[6]=sha2_add64(state[6],g);state[7]=sha2_add64(state[7],h)
}

fn sha2_digest(variant int, input &i64) [64]u8 {
	digest_lengths := [6]int{28,32,48,64,28,32}
	message_length := int(input[1])
	mut padded := [max_padded_bytes]u8{}
	for index in 0 .. message_length { padded[index]=u8(input[2+index]) }
	padded[message_length]=0x80
	mut digest := [64]u8{}
	if variant < 2 {
		mut padded_length:=message_length+1
		for padded_length%64!=56 { padded_length++ }
		padded_length+=8
		bit_length:=u64(message_length)*8
		for byte in 0 .. 8 { padded[padded_length-1-byte]=u8((bit_length>>(8*byte))&255) }
		mut state:=if variant==0 { h224 } else { h256 }
		for offset:=0;offset<padded_length;offset+=64 { sha2_compress32(mut state[0],padded[offset]) }
		for word in 0 .. 8 { for byte in 0 .. 4 { out_index:=word*4+byte;if out_index<digest_lengths[variant] { digest[out_index]=u8((state[word]>>(24-8*byte))&255) } } }
	} else {
		mut padded_length:=message_length+1
		for padded_length%128!=112 { padded_length++ }
		padded_length+=16
		bit_length:=u64(message_length)*8
		for byte in 0 .. 8 { padded[padded_length-1-byte]=u8((bit_length>>(8*byte))&255) }
		mut state:=match variant { 2 { h384 } 3 { h512 } 4 { h512_224 } else { h512_256 } }
		for offset:=0;offset<padded_length;offset+=128 { sha2_compress64(mut state[0],padded[offset]) }
		for word in 0 .. 8 { for byte in 0 .. 8 { out_index:=word*8+byte;if out_index<digest_lengths[variant] { digest[out_index]=u8((state[word]>>(56-8*byte))&255) } } }
	}
	return digest
}

@[export: 'sha2']
pub fn sha2(input &i64, input_length usize, mut output &u8, output_capacity usize) i64 {
	unsafe {
		if input==nil||input_length<2||input_length>usize(max_parseable_input_length) { return -1 }
		if input[0]<0||input[0]>5||input[1]<0||input[1]>max_message_bytes { return -1 }
		variant,message_length:=int(input[0]),int(input[1])
		if int(input_length)!=2+message_length { return -1 }
		for index in 0 .. message_length { if input[2+index]<0||input[2+index]>255 { return -1 } }
		digest_lengths:=[6]int{28,32,48,64,28,32}
		digest_length:=digest_lengths[variant]
		if digest_length>max_output_bytes { return -1 }
		if output==nil||output_capacity<usize(digest_length) { return -2 }
		digest:=sha2_digest(variant,input)
		for index in 0 .. digest_length { output[index]=digest[index] }
		return i64(digest_length)
	}
}
