package queue_using_array2

import "core:c"

MAX_INPUT :: 513
VALUE_LIMIT :: i64(1_000_000)
VALUE_OFFSET :: i64(1_000_001)
HASH_MULTIPLIER :: i64(1_000_003)
HASH_MODULUS :: i64(1_000_000_007)

@(export)
queue_using_array2 :: proc "c" (packed: [^]i64, length: c.size_t) -> i64 {
	if packed == nil || length < 1 || length > MAX_INPUT do return -1
	qv := packed[0]
	if qv < 0 || qv > 256 || length != c.size_t(1 + qv * 2) do return -1
	q := int(qv)
	for i in 0..<q {
		op, value := packed[1 + i * 2], packed[2 + i * 2]
		if op == 1 { if value < -VALUE_LIMIT || value > VALUE_LIMIT do return -1 }
		else if op == 2 || op == 3 { if value != 0 do return -1 }
		else do return -1
	}

	values: [10]i64
	count := 0
	hash := i64(0)
	for i in 0..<q {
		op, value := packed[1 + i * 2], packed[2 + i * 2]
		if op == 1 {
			if count < 10 { values[count] = value; count += 1 }
		} else if op == 2 && count > 0 {
			for j in 1..<count { values[j - 1] = values[j] }
			count -= 1
		}

		hash = (hash * HASH_MULTIPLIER + op) % HASH_MODULUS
		hash = (hash * HASH_MULTIPLIER + i64(count)) % HASH_MODULUS
		for j in 0..<count {
			hash = (hash * HASH_MULTIPLIER + values[j] + VALUE_OFFSET) % HASH_MODULUS
		}
	}
	return hash
}
