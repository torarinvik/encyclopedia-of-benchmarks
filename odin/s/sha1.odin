package sha1

import "core:c"

MAX_INPUT :: 4096
MAX_PADDED :: 4160

rol :: proc "contextless" (value: u32, shift: u32) -> u32 { return (value << shift) | (value >> (32 - shift)) }
add32 :: proc "contextless" (left, right: u32) -> u32 { return u32((u64(left) + u64(right)) & 0xffff_ffff) }

@(export)
sha1 :: proc "c" (input: [^]i64, length: c.size_t, output: [^]u8, capacity: c.size_t) -> i64 {
	if length > MAX_INPUT || (length > 0 && input == nil) do return -1
	n := int(length)
	for i := 0; i < n; i += 1 { if input[i] < 0 || input[i] > 255 do return -1 }
	var padded: [MAX_PADDED]u8
	for i := 0; i < n; i += 1 { padded[i] = u8(input[i]) }
	padded[n] = 0x80
	blocks := (n + 9 + 63) / 64
	padded_length := blocks * 64
	bit_length := u64(n) * 8
	for i := 0; i < 8; i += 1 { padded[padded_length-1-i] = u8((bit_length >> (8*i)) & 255) }
	h0, h1, h2, h3, h4: u32 = 0x67452301, 0xEFCDAB89, 0x98BADCFE, 0x10325476, 0xC3D2E1F0
	for block := 0; block < blocks; block += 1 {
		var w: [80]u32
		for i := 0; i < 16; i += 1 {
			p := block*64+i*4
			w[i] = (u32(padded[p])<<24)|(u32(padded[p+1])<<16)|(u32(padded[p+2])<<8)|u32(padded[p+3])
		}
		for i := 16; i < 80; i += 1 { w[i] = rol(w[i-3]^w[i-8]^w[i-14]^w[i-16], 1) }
		a, b, cc, d, e := h0, h1, h2, h3, h4
		for i := 0; i < 80; i += 1 {
			f, k: u32
			if i < 20 { f=(b&cc)|((~b)&d); k=0x5A827999 }
			else if i < 40 { f=b^cc^d; k=0x6ED9EBA1 }
			else if i < 60 { f=(b&cc)|(b&d)|(cc&d); k=0x8F1BBCDC }
			else { f=b^cc^d; k=0xCA62C1D6 }
			temp := add32(add32(add32(add32(rol(a,5),f),e),k),w[i])
			e=d; d=cc; cc=rol(b,30); b=a; a=temp
		}
		h0=add32(h0,a); h1=add32(h1,b); h2=add32(h2,cc); h3=add32(h3,d); h4=add32(h4,e)
	}
	if output == nil || capacity < 20 do return -2
	digest := [5]u32{h0,h1,h2,h3,h4}
	for i := 0; i < 5; i += 1 { for byte := 0; byte < 4; byte += 1 { output[i*4+byte] = u8((digest[i] >> (24-8*byte)) & 255) } }
	return 20
}
