package two_pset

import "core:c"

MAX_INPUT :: 1025
HASH_MULTIPLIER :: i64(1_000_003)
HASH_MODULUS :: i64(1_000_000_007)

@(export)
two_pset :: proc "c" (packed: [^]i64, length: c.size_t) -> i64 {
	if packed == nil || length < 1 || length > MAX_INPUT do return -1
	qv := packed[0]
	if qv < 0 || qv > 256 || length != c.size_t(1 + qv * 4) do return -1
	q := int(qv)
	for i in 0..<q {
		op, set_id, value, other_id := packed[1 + i * 4], packed[2 + i * 4], packed[3 + i * 4], packed[4 + i * 4]
		if op >= 0 && op <= 2 {
			if set_id < 0 || set_id > 1 || value < 0 || value > 63 || other_id != 0 do return -1
		} else if op == 3 || op == 4 {
			if set_id < 0 || set_id > 1 || value != 0 || other_id < 0 || other_id > 1 do return -1
		} else do return -1
	}

	additions: [128]i64
	tombstones: [128]i64
	hash := i64(0)
	for i in 0..<q {
		op, set_id, value, other_id := packed[1 + i * 4], packed[2 + i * 4], packed[3 + i * 4], packed[4 + i * 4]
		base := int(set_id) * 64
		operation_result := i64(0)
		if op == 0 {
			additions[base + int(value)] = 1
		} else if op == 1 {
			index := base + int(value)
			if additions[index] != 0 && tombstones[index] == 0 do tombstones[index] = 1
		} else if op == 2 {
			index := base + int(value)
			if additions[index] != 0 && tombstones[index] == 0 do operation_result = 1
		} else if op == 3 {
			other_base := int(other_id) * 64
			mut subset := true
			for e in 0..<64 {
				if (additions[base + e] != 0 && additions[other_base + e] == 0) ||
					(tombstones[base + e] != 0 && tombstones[other_base + e] == 0) { subset = false }
			}
			if subset { operation_result = 1 }
		} else {
			other_base := int(other_id) * 64
			for e in 0..<64 {
				if additions[base + e] != 0 || additions[other_base + e] != 0 { additions[base + e] = 1 }
				if tombstones[base + e] != 0 || tombstones[other_base + e] != 0 { tombstones[base + e] = 1 }
			}
		}
		hash = (hash * HASH_MULTIPLIER + op) % HASH_MODULUS
		hash = (hash * HASH_MULTIPLIER + operation_result) % HASH_MODULUS
	}
	for set_id in 0..<2 {
		base := set_id * 64
		for e in 0..<64 { hash = (hash * HASH_MULTIPLIER + additions[base + e]) % HASH_MODULUS }
		for e in 0..<64 { hash = (hash * HASH_MULTIPLIER + tombstones[base + e]) % HASH_MODULUS }
	}
	return hash
}
