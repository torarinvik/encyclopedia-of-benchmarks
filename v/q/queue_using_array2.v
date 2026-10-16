module queue_using_array2

const max_input = 513
const value_limit = i64(1_000_000)
const value_offset = i64(1_000_001)
const hash_multiplier = i64(1_000_003)
const hash_modulus = i64(1_000_000_007)

@[export: 'queue_using_array2']
pub fn queue_using_array2(packed &i64, length usize) i64 {
	if unsafe { packed == nil } || length < 1 || length > max_input { return -1 }
	qv := unsafe { packed[0] }
	if qv < 0 || qv > 256 || length != usize(1 + qv * 2) { return -1 }
	q := int(qv)
	for i in 0 .. q {
		op := unsafe { packed[1 + i * 2] }
		value := unsafe { packed[2 + i * 2] }
		if op == 1 {
			if value < -value_limit || value > value_limit { return -1 }
		} else if op == 2 || op == 3 {
			if value != 0 { return -1 }
		} else { return -1 }
	}

	mut values := []i64{len: 10}
	mut count := 0
	mut hash := i64(0)
	for i in 0 .. q {
		op := unsafe { packed[1 + i * 2] }
		value := unsafe { packed[2 + i * 2] }
		if op == 1 {
			if count < 10 { values[count] = value; count++ }
		} else if op == 2 && count > 0 {
			for j in 1 .. count { values[j - 1] = values[j] }
			count--
		}

		hash = (hash * hash_multiplier + op) % hash_modulus
		hash = (hash * hash_multiplier + i64(count)) % hash_modulus
		for j in 0 .. count {
			hash = (hash * hash_multiplier + values[j] + value_offset) % hash_modulus
		}
	}
	return hash
}
