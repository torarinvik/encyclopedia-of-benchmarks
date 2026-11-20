module base58check_encode

const max_words = 35
const max_payload = 32
const max_base58 = 51
const alphabet = '123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz'
const sha_k = [64]u32{0x428a2f98,0x71374491,0xb5c0fbcf,0xe9b5dba5,0x3956c25b,0x59f111f1,0x923f82a4,0xab1c5ed5,0xd807aa98,0x12835b01,0x243185be,0x550c7dc3,0x72be5d74,0x80deb1fe,0x9bdc06a7,0xc19bf174,0xe49b69c1,0xefbe4786,0x0fc19dc6,0x240ca1cc,0x2de92c6f,0x4a7484aa,0x5cb0a9dc,0x76f988da,0x983e5152,0xa831c66d,0xb00327c8,0xbf597fc7,0xc6e00bf3,0xd5a79147,0x06ca6351,0x14292967,0x27b70a85,0x2e1b2138,0x4d2c6dfc,0x53380d13,0x650a7354,0x766a0abb,0x81c2c92e,0x92722c85,0xa2bfe8a1,0xa81a664b,0xc24b8b70,0xc76c51a3,0xd192e819,0xd6990624,0xf40e3585,0x106aa070,0x19a4c116,0x1e376c08,0x2748774c,0x34b0bcb5,0x391c0cb3,0x4ed8aa4a,0x5b9cca4f,0x682e6ff3,0x748f82ee,0x78a5636f,0x84c87814,0x8cc70208,0x90befffa,0xa4506ceb,0xbef9a3f7,0xc67178f2}

fn rotr(x u32, n u32) u32 { return (x >> n) | (x << (32 - n)) }
fn add32(a u32, b u32) u32 { return u32((u64(a) + u64(b)) & 0xffffffff) }

fn sha256_digest(input &u8, length int, mut output &u8) {
	unsafe {
		mut padded := [64]u8{}
		for i in 0 .. length { padded[i] = input[i] }
		padded[length] = 0x80
		bit_length := u64(length) * 8
		for i in 0 .. 8 { padded[63 - i] = u8((bit_length >> (8 * i)) & 255) }
		mut h := [8]u32{0x6a09e667,0xbb67ae85,0x3c6ef372,0xa54ff53a,0x510e527f,0x9b05688c,0x1f83d9ab,0x5be0cd19}
		mut w := [64]u32{}
		for i in 0 .. 16 { p := i * 4; w[i] = (u32(padded[p]) << 24) | (u32(padded[p+1]) << 16) | (u32(padded[p+2]) << 8) | u32(padded[p+3]) }
		for i in 16 .. 64 { x := w[i-15]; y := w[i-2]; s0 := rotr(x,7) ^ rotr(x,18) ^ (x >> 3); s1 := rotr(y,17) ^ rotr(y,19) ^ (y >> 10); w[i] = add32(add32(add32(s1,w[i-7]),s0),w[i-16]) }
		mut a := h[0]; mut b := h[1]; mut c := h[2]; mut d := h[3]; mut e := h[4]; mut f := h[5]; mut g := h[6]; mut hh := h[7]
		for i in 0 .. 64 {
			s1 := rotr(e,6) ^ rotr(e,11) ^ rotr(e,25); ch := (e & f) ^ ((~e) & g); t1 := add32(add32(add32(add32(hh,s1),ch),sha_k[i]),w[i])
			s0 := rotr(a,2) ^ rotr(a,13) ^ rotr(a,22); maj := (a & b) ^ (a & c) ^ (b & c); t2 := add32(s0,maj)
			hh=g;g=f;f=e;e=add32(d,t1);d=c;c=b;b=a;a=add32(t1,t2)
		}
		h[0]=add32(h[0],a);h[1]=add32(h[1],b);h[2]=add32(h[2],c);h[3]=add32(h[3],d);h[4]=add32(h[4],e);h[5]=add32(h[5],f);h[6]=add32(h[6],g);h[7]=add32(h[7],hh)
		for i in 0 .. 8 { for byte in 0 .. 4 { output[i*4+byte] = u8((h[i] >> (24 - 8 * byte)) & 255) } }
	}
}

@[export: 'base58check_encode']
pub fn base58check_encode(values &i64, length usize, mut output &u8, output_capacity usize) i64 {
	if length < 2 || length > max_words { return -1 }
	unsafe {
		if values == nil { return -1 }
		version := values[0]; payload_value := values[1]
		if version < 0 || version > 255 || payload_value < 0 || payload_value > 32 { return -1 }
		payload_length := int(payload_value)
		if length != usize(payload_length + 2) { return -1 }
		mut message := [33]u8{}
		mut first_digest := [32]u8{}
		mut second_digest := [32]u8{}
		mut raw := [37]u8{}
		message[0] = u8(version); raw[0] = u8(version)
		for i in 0 .. payload_length {
			value := values[i+2]
			if value < 0 || value > 255 { return -1 }
			message[i+1] = u8(value); raw[i+1] = u8(value)
		}
		message_length := payload_length + 1
		sha256_digest(&message[0], message_length, &first_digest[0])
		mut second_input := [33]u8{}
		for i in 0 .. 32 { second_input[i] = first_digest[i] }
		sha256_digest(&second_input[0], 32, &second_digest[0])
		raw_length := message_length + 4
		for i in 0 .. 4 { raw[message_length+i] = second_digest[i] }
		mut leading_zeroes := 0
		for leading_zeroes < raw_length && raw[leading_zeroes] == 0 { leading_zeroes++ }
		mut digits := [max_base58]u8{}
		mut digit_count := 0
		for i in leading_zeroes .. raw_length {
			mut carry := u32(raw[i])
			for j in 0 .. digit_count { carry += u32(digits[j]) * 256; digits[j] = u8(carry % 58); carry /= 58 }
			for carry > 0 { digits[digit_count] = u8(carry % 58); digit_count++; carry /= 58 }
		}
		encoded_length := leading_zeroes + digit_count
		if output == nil || output_capacity < usize(encoded_length) { return -2 }
		mut written := 0
		for written < leading_zeroes { output[written] = 49; written++ }
		for digit_count > 0 { digit_count--; output[written] = alphabet[digits[digit_count]]; written++ }
		return i64(encoded_length)
	}
}
