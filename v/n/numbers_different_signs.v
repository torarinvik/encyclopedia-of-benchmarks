module numbers_different_signs

const int32_min_value = i64(-2147483648)
const int32_max_value = i64(2147483647)

// Return whether the signed 32-bit XOR has its sign bit set.
@[export: 'numbers_different_signs']
pub fn numbers_different_signs(left i64, right i64) i64 {
	if left < int32_min_value || left > int32_max_value || right < int32_min_value || right > int32_max_value {
		return -1
	}
	return if (i32(left) ^ i32(right)) < 0 { 1 } else { 0 }
}
