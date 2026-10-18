package lamport_signature

import "core:c"

MAX_INPUT :: 64
MAX_PADDED :: 128
K :: [64]u32{0x428a2f98,0x71374491,0xb5c0fbcf,0xe9b5dba5,0x3956c25b,0x59f111f1,0x923f82a4,0xab1c5ed5,0xd807aa98,0x12835b01,0x243185be,0x550c7dc3,0x72be5d74,0x80deb1fe,0x9bdc06a7,0xc19bf174,0xe49b69c1,0xefbe4786,0x0fc19dc6,0x240ca1cc,0x2de92c6f,0x4a7484aa,0x5cb0a9dc,0x76f988da,0x983e5152,0xa831c66d,0xb00327c8,0xbf597fc7,0xc6e00bf3,0xd5a79147,0x06ca6351,0x14292967,0x27b70a85,0x2e1b2138,0x4d2c6dfc,0x53380d13,0x650a7354,0x766a0abb,0x81c2c92e,0x92722c85,0xa2bfe8a1,0xa81a664b,0xc24b8b70,0xc76c51a3,0xd192e819,0xd6990624,0xf40e3585,0x106aa070,0x19a4c116,0x1e376c08,0x2748774c,0x34b0bcb5,0x391c0cb3,0x4ed8aa4a,0x5b9cca4f,0x682e6ff3,0x748f82ee,0x78a5636f,0x84c87814,0x8cc70208,0x90befffa,0xa4506ceb,0xbef9a3f7,0xc67178f2}

rotr :: proc "contextless" (x: u32, n: u32) -> u32 { return (x >> n) | (x << (32-n)) }
add32 :: proc "contextless" (a,b:u32)->u32{return u32((u64(a)+u64(b))&0xffff_ffff)}

lamport_sha256 :: proc "c" (input:[^]i64,length:c.size_t,output:[^]u8,capacity:c.size_t)->i64 {
	if length>MAX_INPUT||(length>0&&input==nil) do return -1
	n:=int(length);for i:=0;i<n;i+=1{if input[i]<0||input[i]>255 do return -1}
	var padded:[MAX_PADDED]u8;for i:=0;i<MAX_PADDED;i+=1{padded[i]=0};for i:=0;i<n;i+=1{padded[i]=u8(input[i])};padded[n]=0x80
	blocks:=(n+9+63)/64;padded_length:=blocks*64;bit_length:=u64(n)*8;for i:=0;i<8;i+=1{padded[padded_length-1-i]=u8((bit_length>>(8*i))&255)}
	h:=[8]u32{0x6a09e667,0xbb67ae85,0x3c6ef372,0xa54ff53a,0x510e527f,0x9b05688c,0x1f83d9ab,0x5be0cd19}
	for block:=0;block<blocks;block+=1{
		var w:[64]u32
		for i:=0;i<16;i+=1{p:=block*64+i*4;w[i]=(u32(padded[p])<<24)|(u32(padded[p+1])<<16)|(u32(padded[p+2])<<8)|u32(padded[p+3])}
		for i:=16;i<64;i+=1{x:=w[i-15];y:=w[i-2];s0:=rotr(x,7)^rotr(x,18)^(x>>3);s1:=rotr(y,17)^rotr(y,19)^(y>>10);w[i]=add32(add32(add32(s1,w[i-7]),s0),w[i-16])}
		a,b,cc,d,e,f,g,hh:=h[0],h[1],h[2],h[3],h[4],h[5],h[6],h[7]
		for i:=0;i<64;i+=1{s1:=rotr(e,6)^rotr(e,11)^rotr(e,25);ch:=(e&f)^(~e&g);t1:=add32(add32(add32(add32(hh,s1),ch),K[i]),w[i]);s0:=rotr(a,2)^rotr(a,13)^rotr(a,22);maj:=(a&b)^(a&cc)^(b&cc);t2:=add32(s0,maj);hh=g;g=f;f=e;e=add32(d,t1);d=cc;cc=b;b=a;a=add32(t1,t2)}
		h[0]=add32(h[0],a);h[1]=add32(h[1],b);h[2]=add32(h[2],cc);h[3]=add32(h[3],d);h[4]=add32(h[4],e);h[5]=add32(h[5],f);h[6]=add32(h[6],g);h[7]=add32(h[7],hh)
	}
	if output==nil||capacity<32 do return -2
	for i:=0;i<8;i+=1{for byte:=0;byte<4;byte+=1{output[i*4+byte]=u8((h[i]>>(24-8*byte))&255)}}
	return 32
}

LAMPORT_MAX_MESSAGE :: 64
LAMPORT_DIGEST_BITS :: 256
LAMPORT_SECRET_BYTES :: 32
LAMPORT_ENTROPY_BYTES :: LAMPORT_DIGEST_BITS * 2 * LAMPORT_SECRET_BYTES
LAMPORT_SIGNATURE_BYTES :: LAMPORT_DIGEST_BITS * LAMPORT_SECRET_BYTES
LAMPORT_MAX_PARSEABLE :: 4 + 2 * LAMPORT_MAX_MESSAGE + LAMPORT_ENTROPY_BYTES + 1

@(export)
lamport_signature :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
    if input == nil || length < LAMPORT_ENTROPY_BYTES + 4 || length > LAMPORT_MAX_PARSEABLE do return -1
    if input[0] < 0 || input[0] > LAMPORT_MAX_MESSAGE do return -1
    message_length := int(input[0])
    verify_length_index := 1 + message_length
    if verify_length_index >= int(length) || input[verify_length_index] < 0 || input[verify_length_index] > LAMPORT_MAX_MESSAGE do return -1
    verify_length := int(input[verify_length_index])
    verify_start := verify_length_index + 1
    verify_end := verify_start + verify_length
    if verify_end + 2 > int(length) do return -1
    tamper_index := input[verify_end]
    sign_twice := input[verify_end + 1]
    entropy_start := verify_end + 2
    if int(length) != entropy_start + LAMPORT_ENTROPY_BYTES do return -1
    if tamper_index < -1 || tamper_index >= LAMPORT_SIGNATURE_BYTES || (sign_twice != 0 && sign_twice != 1) do return -1
    for i := 0; i < message_length; i += 1 { if input[1+i] < 0 || input[1+i] > 255 do return -1 }
    for i := 0; i < verify_length; i += 1 { if input[verify_start+i] < 0 || input[verify_start+i] > 255 do return -1 }
    for i := 0; i < LAMPORT_ENTROPY_BYTES; i += 1 { if input[entropy_start+i] < 0 || input[entropy_start+i] > 255 do return -1 }

    public_key: [LAMPORT_DIGEST_BITS][2][32]u8 = {}
    signature: [LAMPORT_SIGNATURE_BYTES]i64 = {}
    message_digest: [32]u8
    for bit := 0; bit < LAMPORT_DIGEST_BITS; bit += 1 {
        for value := 0; value < 2; value += 1 {
            secret_offset := entropy_start + (bit*2+value)*LAMPORT_SECRET_BYTES
            if lamport_sha256(&input[secret_offset], LAMPORT_SECRET_BYTES, &public_key[bit][value][0], 32) != 32 do return -1
        }
    }
    if lamport_sha256(&input[1], message_length, &message_digest[0], 32) != 32 do return -1
    for bit := 0; bit < LAMPORT_DIGEST_BITS; bit += 1 {
        value := int((message_digest[bit/8] >> u32(7-(bit%8))) & 1)
        secret_offset := entropy_start + (bit*2+value)*LAMPORT_SECRET_BYTES
        for byte := 0; byte < LAMPORT_SECRET_BYTES; byte += 1 { signature[bit*LAMPORT_SECRET_BYTES+byte] = input[secret_offset+byte] }
    }
    if sign_twice == 1 do return -1

    if tamper_index >= 0 { signature[int(tamper_index)] = signature[int(tamper_index)] ^ 1 }
    verify_digest: [32]u8
    if lamport_sha256(&input[verify_start], verify_length, &verify_digest[0], 32) != 32 do return -1
    verified := true
    for bit := 0; bit < LAMPORT_DIGEST_BITS; bit += 1 {
        value := int((verify_digest[bit/8] >> u32(7-(bit%8))) & 1)
        actual_hash: [32]u8
        if lamport_sha256(&signature[bit*LAMPORT_SECRET_BYTES], LAMPORT_SECRET_BYTES, &actual_hash[0], 32) != 32 do return -1
        for byte := 0; byte < 32; byte += 1 {
            if actual_hash[byte] != public_key[bit][value][byte] { verified = false; break }
        }
        if !verified do break
    }
    if tamper_index >= 0 { signature[int(tamper_index)] = signature[int(tamper_index)] ^ 1 }

    fingerprint := u64(0xcbf29ce484222325)
    for bit := 0; bit < LAMPORT_DIGEST_BITS; bit += 1 {
        for value := 0; value < 2; value += 1 {
            for byte := 0; byte < 32; byte += 1 { fingerprint = (fingerprint ^ u64(public_key[bit][value][byte])) * u64(0x100000001b3) }
        }
    }
    for i := 0; i < LAMPORT_SIGNATURE_BYTES; i += 1 { fingerprint = (fingerprint ^ u64(u8(signature[i]))) * u64(0x100000001b3) }
    verify_byte := u64(0)
    if verified do verify_byte = 1
    fingerprint = (fingerprint ^ verify_byte) * u64(0x100000001b3)
    return i64(fingerprint & 0x7fffffffffffffff)
}
