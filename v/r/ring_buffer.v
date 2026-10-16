module ring_buffer

const max_input = 513
const value_limit = i64(1_000_000)
const value_offset = i64(1_000_001)
const hash_multiplier = i64(1_000_003)
const hash_modulus = i64(1_000_000_007)

@[export: 'ring_buffer']
pub fn ring_buffer(packed &i64, length usize) i64 {
	if unsafe { packed == nil } || length < 1 || length > max_input { return -1 }
	qv := unsafe { packed[0] }
	if qv < 0 || qv > 256 || length != usize(1 + qv * 2) { return -1 }
	q := int(qv)
	for i in 0 .. q {
		op := unsafe { packed[1 + i * 2] }
		payload := unsafe { packed[2 + i * 2] }
		if op == 0 {
			if payload < -value_limit || payload > value_limit { return -1 }
		} else if op == 4 {
			if payload < 0 || payload > value_limit { return -1 }
		} else if op >= 1 && op <= 3 {
			if payload != 0 { return -1 }
		} else if op >= 5 && op <= 9 {
			if payload != 0 { return -1 }
		} else { return -1 }
	}

	mut values := []i64{len: 8}
	mut head := 0
	mut tail := 0
	mut count := 0
	mut hash := i64(0)
	for i in 0 .. q {
		op := unsafe { packed[1 + i * 2] }
		payload := unsafe { packed[2 + i * 2] }
		mut status := i64(0)
		mut result := i64(0)
		if op == 0 {
			if count == 8 { status = 1 }
			else { values[tail] = payload; tail = (tail + 1) % 8; count++ }
		} else if op == 1 {
			if count == 0 { status = 2 }
			else { result = values[head]; head = (head + 1) % 8; count-- }
		} else if op == 2 {
			if count == 0 { status = 2 } else { result = values[head] }
		} else if op == 3 {
			if count == 0 { status = 2 } else { result = values[(tail + 7) % 8] }
		} else if op == 4 {
			if payload >= i64(count) { status = 3 }
			else { result = values[(head + int(payload)) % 8] }
		} else if op == 5 {
			head = 0; tail = 0; count = 0
		} else if op == 6 { result = i64(count) }
		else if op == 7 { result = 8 - i64(count) }
		else if op == 8 { if count == 0 { result = 1 } }
		else { if count == 8 { result = 1 } }

		hash = (hash * hash_multiplier + op) % hash_modulus
		hash = (hash * hash_multiplier + status) % hash_modulus
		hash = (hash * hash_multiplier + result + value_offset) % hash_modulus
		hash = (hash * hash_multiplier + i64(count)) % hash_modulus
		for j in 0 .. count {
			position := (head + j) % 8
			hash = (hash * hash_multiplier + values[position] + value_offset) % hash_modulus
		}
	}
	return hash
}
