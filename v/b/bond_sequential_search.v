module bond_sequential_search

const max_n = 64
const max_value = i64(255)
const absent_code = i64(64)
const pack_base = i64(65)

@[export: 'bond_sequential_search']
pub fn bond_sequential_search(input &i64, length usize) i64 {
	if input == nil || length < 3 || length > max_n + 4 { return -1 }
	count_value := unsafe { input[0] }
	key_a := unsafe { input[1] }
	key_b := unsafe { input[2] }
	if count_value < 0 || count_value > max_n || length != usize(count_value + 3) { return -1 }
	if key_a < 0 || key_a > max_value || key_b < 0 || key_b > max_value || key_a == key_b { return -1 }
	count := int(count_value)
	for i in 0 .. count {
		value := unsafe { input[i + 3] }
		if value < 0 || value > max_value { return -1 }
	}

	mut index_a := absent_code
	mut index_b := absent_code
	composite := key_a | key_b
	for i in 0 .. count {
		if index_a != absent_code && index_b != absent_code { break }
		value := unsafe { input[i + 3] }
		if value & composite != value { continue }
		if index_a == absent_code && value == key_a { index_a = i64(i) }
		if index_b == absent_code && value == key_b { index_b = i64(i) }
	}
	return index_a * pack_base + index_b
}
