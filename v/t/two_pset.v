module two_pset

const max_input = 1025
const hash_multiplier = i64(1_000_003)
const hash_modulus = i64(1_000_000_007)

@[export: 'two_pset']
pub fn two_pset(packed &i64, length usize) i64 {
	if unsafe { packed == nil } || length < 1 || length > max_input { return -1 }
	qv := unsafe { packed[0] }
	if qv < 0 || qv > 256 || length != usize(1 + qv * 4) { return -1 }
	q := int(qv)
	for i in 0 .. q {
		op := unsafe { packed[1 + i * 4] }
		set_id := unsafe { packed[2 + i * 4] }
		value := unsafe { packed[3 + i * 4] }
		other_id := unsafe { packed[4 + i * 4] }
		if op >= 0 && op <= 2 {
			if set_id < 0 || set_id > 1 || value < 0 || value > 63 || other_id != 0 { return -1 }
		} else if op == 3 || op == 4 {
			if set_id < 0 || set_id > 1 || value != 0 || other_id < 0 || other_id > 1 { return -1 }
		} else { return -1 }
	}

	mut additions := []i64{len: 128}
	mut tombstones := []i64{len: 128}
	mut digest := i64(0)
	for i in 0 .. q {
		op := unsafe { packed[1 + i * 4] }
		set_id := int(unsafe { packed[2 + i * 4] })
		value := unsafe { packed[3 + i * 4] }
		other_id := int(unsafe { packed[4 + i * 4] })
		base := set_id * 64
		mut operation_result := i64(0)
		if op == 0 {
			additions[base + int(value)] = 1
		} else if op == 1 {
			index := base + int(value)
			if additions[index] != 0 && tombstones[index] == 0 { tombstones[index] = 1 }
		} else if op == 2 {
			index := base + int(value)
			if additions[index] != 0 && tombstones[index] == 0 { operation_result = 1 }
		} else if op == 3 {
			other_base := other_id * 64
			mut subset := true
			for e in 0 .. 64 {
				if (additions[base + e] != 0 && additions[other_base + e] == 0) ||
					(tombstones[base + e] != 0 && tombstones[other_base + e] == 0) { subset = false }
			}
			if subset { operation_result = 1 }
		} else {
			other_base := other_id * 64
			for e in 0 .. 64 {
				if additions[base + e] != 0 || additions[other_base + e] != 0 { additions[base + e] = 1 }
				if tombstones[base + e] != 0 || tombstones[other_base + e] != 0 { tombstones[base + e] = 1 }
			}
		}
		digest = (digest * hash_multiplier + op) % hash_modulus
		digest = (digest * hash_multiplier + operation_result) % hash_modulus
	}
	for set_id in 0 .. 2 {
		base := set_id * 64
		for e in 0 .. 64 { digest = (digest * hash_multiplier + additions[base + e]) % hash_modulus }
		for e in 0 .. 64 { digest = (digest * hash_multiplier + tombstones[base + e]) % hash_modulus }
	}
	return digest
}
