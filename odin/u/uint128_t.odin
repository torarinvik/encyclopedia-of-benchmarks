package uint128_t

import "core:c"

LIMBS :: 4

divide_words :: proc "contextless" (dividend, divisor: [LIMBS]u32,
		quotient, remainder: ^[LIMBS]u32) {
	var rem: [LIMBS + 1]u32 = {}
	for offset := 0; offset < LIMBS * 32; offset += 1 {
		bit := LIMBS * 32 - 1 - offset
		carry := (dividend[bit / 32] >> u32(bit % 32)) & 1
		for i := 0; i < LIMBS; i += 1 {
			next := rem[i] >> 31
			rem[i] = (rem[i] << 1) | carry
			carry = next
		}
		rem[LIMBS] = carry
		comparison := 0
		if rem[LIMBS] != 0 do comparison = 1
		if comparison == 0 {
			i := LIMBS
			for i > 0 {
				i -= 1
				if rem[i] > divisor[i] { comparison = 1; break }
				if rem[i] < divisor[i] { comparison = -1; break }
			}
		}
		if comparison >= 0 {
			borrow: u64 = 0
			for i := 0; i < LIMBS; i += 1 {
				sub := u64(divisor[i]) + borrow
				old := u64(rem[i])
				if old >= sub { rem[i] = u32(old - sub); borrow = 0 }
				else { rem[i] = u32(old + u64(0x1_0000_0000) - sub); borrow = 1 }
			}
			rem[LIMBS] = u32(u64(rem[LIMBS]) - borrow)
			quotient[bit / 32] |= u32(1) << u32(bit % 32)
		}
	}
	for i := 0; i < LIMBS; i += 1 do remainder[i] = rem[i]
}

@(export)
uint128_t :: proc "c" (input: [^]i64, length: c.size_t, output: [^]u8, capacity: c.size_t) -> i64 {
	if input == nil || length < 1 || length > 10 || length != 1 + 2 * LIMBS do return -1
	if input[0] != 0 && input[0] != 1 do return -1
	var dividend: [LIMBS]u32 = {}
	var divisor: [LIMBS]u32 = {}
	divisor_nonzero := false
	for i := 0; i < LIMBS; i += 1 {
		a, b := input[1 + i], input[1 + LIMBS + i]
		if a < 0 || a > 4_294_967_295 || b < 0 || b > 4_294_967_295 do return -1
		dividend[i], divisor[i] = u32(a), u32(b)
		divisor_nonzero = divisor_nonzero || divisor[i] != 0
	}
	if !divisor_nonzero do return -1
	if output == nil || capacity < 16 do return -2
	var quotient: [LIMBS]u32 = {}
	var remainder: [LIMBS]u32 = {}
	divide_words(dividend, divisor, &quotient, &remainder)
	answer := quotient
	if input[0] == 1 do answer = remainder
	for i := 0; i < LIMBS; i += 1 {
		for byte := 0; byte < 4; byte += 1 do output[i * 4 + byte] = u8(answer[i] >> (byte * 8))
	}
	return 16
}
