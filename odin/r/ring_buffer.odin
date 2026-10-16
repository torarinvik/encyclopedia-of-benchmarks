package ring_buffer

import "core:c"

MAX_INPUT :: 513
VALUE_LIMIT :: i64(1_000_000)
VALUE_OFFSET :: i64(1_000_001)
HASH_MULTIPLIER :: i64(1_000_003)
HASH_MODULUS :: i64(1_000_000_007)

@(export)
ring_buffer :: proc "c" (packed: [^]i64, length: c.size_t) -> i64 {
	if packed == nil || length < 1 || length > MAX_INPUT do return -1
	qv := packed[0]
	if qv < 0 || qv > 256 || length != c.size_t(1 + qv * 2) do return -1
	q := int(qv)
	for i in 0..<q {
		op, payload := packed[1 + i * 2], packed[2 + i * 2]
		if op == 0 { if payload < -VALUE_LIMIT || payload > VALUE_LIMIT do return -1 }
		else if op == 4 { if payload < 0 || payload > VALUE_LIMIT do return -1 }
		else if op >= 1 && op <= 3 { if payload != 0 do return -1 }
		else if op >= 5 && op <= 9 { if payload != 0 do return -1 }
		else do return -1
	}

	values: [8]i64
	head, tail, count := 0, 0, 0
	hash := i64(0)
	for i in 0..<q {
		op, payload := packed[1 + i * 2], packed[2 + i * 2]
		status, result := i64(0), i64(0)
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
			if payload >= i64(count) { status = 3 } else { result = values[(head + int(payload)) % 8] }
		} else if op == 5 {
			head, tail, count = 0, 0, 0
		} else if op == 6 { result = i64(count) }
		else if op == 7 { result = 8 - i64(count) }
		else if op == 8 { if count == 0 { result = 1 } }
		else { if count == 8 { result = 1 } }

		hash = (hash * HASH_MULTIPLIER + op) % HASH_MODULUS
		hash = (hash * HASH_MULTIPLIER + status) % HASH_MODULUS
		hash = (hash * HASH_MULTIPLIER + result + VALUE_OFFSET) % HASH_MODULUS
		hash = (hash * HASH_MULTIPLIER + i64(count)) % HASH_MODULUS
		for j in 0..<count {
			position := (head + j) % 8
			hash = (hash * HASH_MULTIPLIER + values[position] + VALUE_OFFSET) % HASH_MODULUS
		}
	}
	return hash
}
