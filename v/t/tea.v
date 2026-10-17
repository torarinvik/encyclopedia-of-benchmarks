module tea

const tea_delta = u32(0x9e3779b9)
const tea_decrypt_sum = u32(0xc6ef3720)

fn combine_words(low u32, high u32) u64 {
	return (u64(high) << 32) | u64(low)
}

fn tea_encrypt(block u64, key0 u64, key1 u64) u64 {
	mut b0 := u32(block)
	mut b1 := u32(block >> 32)
	k0 := u32(key0)
	k1 := u32(key0 >> 32)
	k2 := u32(key1)
	k3 := u32(key1 >> 32)
	mut sum := u32(0)
	for _ in 0 .. 32 {
		sum = sum +% tea_delta
		b0 = b0 +% (((b1 << 4) +% k0) ^ (b1 +% sum) ^ ((b1 >> 5) +% k1))
		b1 = b1 +% (((b0 << 4) +% k2) ^ (b0 +% sum) ^ ((b0 >> 5) +% k3))
	}
	return (u64(b1) << 32) | u64(b0)
}

fn tea_decrypt(block u64, key0 u64, key1 u64) u64 {
	mut b0 := u32(block)
	mut b1 := u32(block >> 32)
	k0 := u32(key0)
	k1 := u32(key0 >> 32)
	k2 := u32(key1)
	k3 := u32(key1 >> 32)
	mut sum := tea_decrypt_sum
	for _ in 0 .. 32 {
		b1 = b1 -% (((b0 << 4) +% k2) ^ (b0 +% sum) ^ ((b0 >> 5) +% k3))
		b0 = b0 -% (((b1 << 4) +% k0) ^ (b1 +% sum) ^ ((b1 >> 5) +% k1))
		sum = sum -% tea_delta
	}
	return (u64(b1) << 32) | u64(b0)
}

fn store_u64_le(output &u8, offset int, value u64) {
	unsafe {
		for byte in 0 .. 8 {
			output[offset + byte] = u8((value >> u64(byte * 8)) & 255)
		}
	}
}

@[export: 'tea']
pub fn tea(input &i64, length usize, output &u8, output_capacity usize) i64 {
	unsafe {
		if input == nil || length != 6 { return -1 }
		for index in 0 .. 6 {
			if input[index] < -2147483648 || input[index] > 2147483647 { return -1 }
		}
		if output == nil || output_capacity < 16 { return -2 }
		block := combine_words(u32(i32(input[0])), u32(i32(input[1])))
		key0 := combine_words(u32(i32(input[2])), u32(i32(input[3])))
		key1 := combine_words(u32(i32(input[4])), u32(i32(input[5])))
		ciphertext := tea_encrypt(block, key0, key1)
		recovered := tea_decrypt(ciphertext, key0, key1)
		store_u64_le(output, 0, ciphertext)
		store_u64_le(output, 8, recovered)
		return 16
	}
}
