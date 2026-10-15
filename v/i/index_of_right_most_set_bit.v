module index_of_right_most_set_bit

const int32_min_value = i64(-2_147_483_648)
const int32_max_value = i64(2_147_483_647)

// Zero-based trailing set-bit index using the Java magnitude behavior.
@[export: 'index_of_right_most_set_bit']
pub fn index_of_right_most_set_bit(value i64) i64 {
	if value < int32_min_value || value > int32_max_value || value == 0 { return -1 }
	mut magnitude := if value < 0 { -value } else { value }
	mut index := i64(0)
	for magnitude % 2 == 0 {
		magnitude /= 2
		index++
	}
	return index
}
