module first_different_bit

const int32_min_value = i64(-2147483648)
const int32_max_value = i64(2147483647)

// Return the trailing-zero count of the signed 32-bit XOR.
@[export: 'first_different_bit']
pub fn first_different_bit(x i64, y i64) i64 {
	if x < int32_min_value || x > int32_max_value || y < int32_min_value || y > int32_max_value {
		return -1
	}
	mut difference := u32(i32(x)) ^ u32(i32(y))
	mut index := i64(0)
	for index < 32 && (difference & u32(1)) == 0 {
		index++
		difference >>= 1
	}
	return index
}
