module lamport_signature

const max_input = 64
const max_padded = 128
const k = [64]u32{0x428a2f98,0x71374491,0xb5c0fbcf,0xe9b5dba5,0x3956c25b,0x59f111f1,0x923f82a4,0xab1c5ed5,0xd807aa98,0x12835b01,0x243185be,0x550c7dc3,0x72be5d74,0x80deb1fe,0x9bdc06a7,0xc19bf174,0xe49b69c1,0xefbe4786,0x0fc19dc6,0x240ca1cc,0x2de92c6f,0x4a7484aa,0x5cb0a9dc,0x76f988da,0x983e5152,0xa831c66d,0xb00327c8,0xbf597fc7,0xc6e00bf3,0xd5a79147,0x06ca6351,0x14292967,0x27b70a85,0x2e1b2138,0x4d2c6dfc,0x53380d13,0x650a7354,0x766a0abb,0x81c2c92e,0x92722c85,0xa2bfe8a1,0xa81a664b,0xc24b8b70,0xc76c51a3,0xd192e819,0xd6990624,0xf40e3585,0x106aa070,0x19a4c116,0x1e376c08,0x2748774c,0x34b0bcb5,0x391c0cb3,0x4ed8aa4a,0x5b9cca4f,0x682e6ff3,0x748f82ee,0x78a5636f,0x84c87814,0x8cc70208,0x90befffa,0xa4506ceb,0xbef9a3f7,0xc67178f2}
fn rotr(x u32, n u32) u32 { return (x >> n) | (x << (32 - n)) }
fn add32(a u32, b u32) u32 { return u32((u64(a) + u64(b)) & 0xffffffff) }

fn lamport_sha256(input &i64, length usize, mut output &u8, capacity usize) i64 {
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

const lamport_max_message = 64
const lamport_digest_bits = 256
const lamport_secret_bytes = 32
const lamport_entropy_bytes = lamport_digest_bits * 2 * lamport_secret_bytes
const lamport_signature_bytes = lamport_digest_bits * lamport_secret_bytes
const lamport_max_parseable = 4 + 2 * lamport_max_message + lamport_entropy_bytes + 1

@[export: 'lamport_signature']
pub fn lamport_signature(input &i64, length usize) i64 {
    unsafe {
        if input == nil || length < lamport_entropy_bytes + 4 || length > lamport_max_parseable { return -1 }
        if input[0] < 0 || input[0] > lamport_max_message { return -1 }
        message_length := int(input[0])
        verify_length_index := 1 + message_length
        if verify_length_index >= int(length) || input[verify_length_index] < 0 || input[verify_length_index] > lamport_max_message { return -1 }
        verify_length := int(input[verify_length_index])
        verify_start := verify_length_index + 1
        verify_end := verify_start + verify_length
        if verify_end + 2 > int(length) { return -1 }
        tamper_index := input[verify_end]
        sign_twice := input[verify_end + 1]
        entropy_start := verify_end + 2
        if int(length) != entropy_start + lamport_entropy_bytes { return -1 }
        if tamper_index < -1 || tamper_index >= lamport_signature_bytes || (sign_twice != 0 && sign_twice != 1) { return -1 }
        for i in 0 .. message_length { if input[1+i] < 0 || input[1+i] > 255 { return -1 } }
        for i in 0 .. verify_length { if input[verify_start+i] < 0 || input[verify_start+i] > 255 { return -1 } }
        for i in 0 .. lamport_entropy_bytes { if input[entropy_start+i] < 0 || input[entropy_start+i] > 255 { return -1 } }

        mut public_key := [lamport_digest_bits][2][32]u8{}
        mut signature := [lamport_signature_bytes]i64{}
        mut message_digest := [32]u8{}
        for bit in 0 .. lamport_digest_bits {
            for value in 0 .. 2 {
                secret_offset := entropy_start + (bit * 2 + value) * lamport_secret_bytes
                if lamport_sha256(&input[secret_offset], lamport_secret_bytes, &public_key[bit][value][0], 32) != 32 { return -1 }
            }
        }
        if lamport_sha256(&input[1], message_length, &message_digest[0], 32) != 32 { return -1 }
        for bit in 0 .. lamport_digest_bits {
            value := int((message_digest[bit / 8] >> u32(7 - (bit % 8))) & 1)
            secret_offset := entropy_start + (bit * 2 + value) * lamport_secret_bytes
            for byte in 0 .. lamport_secret_bytes { signature[bit * lamport_secret_bytes + byte] = input[secret_offset + byte] }
        }
        if sign_twice == 1 { return -1 }

        if tamper_index >= 0 { signature[int(tamper_index)] = signature[int(tamper_index)] ^ 1 }
        mut verify_digest := [32]u8{}
        if lamport_sha256(&input[verify_start], verify_length, &verify_digest[0], 32) != 32 { return -1 }
        mut verified := true
        for bit in 0 .. lamport_digest_bits {
            value := int((verify_digest[bit / 8] >> u32(7 - (bit % 8))) & 1)
            mut actual_hash := [32]u8{}
            if lamport_sha256(&signature[bit * lamport_secret_bytes], lamport_secret_bytes, &actual_hash[0], 32) != 32 { return -1 }
            for byte in 0 .. 32 {
                if actual_hash[byte] != public_key[bit][value][byte] { verified = false; break }
            }
            if !verified { break }
        }
        if tamper_index >= 0 { signature[int(tamper_index)] = signature[int(tamper_index)] ^ 1 }

        mut fingerprint := u64(0xcbf29ce484222325)
        for bit in 0 .. lamport_digest_bits {
            for value in 0 .. 2 {
                for byte in 0 .. 32 { fingerprint = (fingerprint ^ u64(public_key[bit][value][byte])) * u64(0x100000001b3) }
            }
        }
        for i in 0 .. lamport_signature_bytes { fingerprint = (fingerprint ^ u64(u8(signature[i]))) * u64(0x100000001b3) }
        verify_byte := u64(0)
        if verified { verify_byte = 1 }
        fingerprint = (fingerprint ^ verify_byte) * u64(0x100000001b3)
        return i64(fingerprint & u64(0x7fffffffffffffff))
    }
}
