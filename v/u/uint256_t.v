module uint256_t

const limbs = 8

fn divide_words(dividend []u32, divisor []u32, mut quotient []u32, mut remainder []u32) {
	mut rem := []u32{len: limbs + 1, init: u32(0)}
	for offset in 0 .. limbs * 32 {
		bit := limbs * 32 - 1 - offset
		mut carry := (dividend[bit / 32] >> u32(bit % 32)) & u32(1)
		for i in 0 .. limbs {
			next := rem[i] >> 31
			rem[i] = (rem[i] << 1) | carry
			carry = next
		}
		rem[limbs] = carry
		mut comparison := if rem[limbs] == 0 { 0 } else { 1 }
		if comparison == 0 {
			mut i := limbs
			for i > 0 {
				i--
				if rem[i] > divisor[i] { comparison = 1; break }
				if rem[i] < divisor[i] { comparison = -1; break }
			}
		}
		if comparison >= 0 {
			mut borrow := u64(0)
			for i in 0 .. limbs {
				sub := u64(divisor[i]) + borrow
				old := u64(rem[i])
				if old >= sub { rem[i] = u32(old - sub); borrow = 0 }
				else { rem[i] = u32(old + u64(0x1_0000_0000) - sub); borrow = 1 }
			}
			rem[limbs] = u32(u64(rem[limbs]) - borrow)
			quotient[bit / 32] |= u32(1) << u32(bit % 32)
		}
	}
	for i in 0 .. limbs { remainder[i] = rem[i] }
}

@[export: 'uint256_t']
pub fn uint256_t(input &i64, length usize, mut output &u8, capacity usize) i64 {
	if unsafe { input == nil } || length < 1 || length > 18 || length != 1 + 2 * limbs { return -1 }
	unsafe {
		if input[0] != 0 && input[0] != 1 { return -1 }
		mut dividend := []u32{len: limbs, init: u32(0)}
		mut divisor := []u32{len: limbs, init: u32(0)}
		mut divisor_nonzero := false
		for i in 0 .. limbs {
			a := input[1 + i]
			b := input[1 + limbs + i]
			if a < 0 || a > 4_294_967_295 || b < 0 || b > 4_294_967_295 { return -1 }
			dividend[i] = u32(a)
			divisor[i] = u32(b)
			divisor_nonzero = divisor_nonzero || divisor[i] != 0
		}
		if !divisor_nonzero { return -1 }
		if output == nil || capacity < 32 { return -2 }
		mut quotient := []u32{len: limbs, init: u32(0)}
		mut remainder := []u32{len: limbs, init: u32(0)}
		divide_words(dividend, divisor, mut quotient, mut remainder)
		answer := if input[0] == 0 { quotient } else { remainder }
		for i in 0 .. limbs {
			for byte in 0 .. 4 { output[i * 4 + byte] = u8(answer[i] >> u32(byte * 8)) }
		}
		return 32
	}
}
