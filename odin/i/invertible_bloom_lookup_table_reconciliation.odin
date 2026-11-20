package invertible_bloom_lookup_table_reconciliation

import "core:c"

SET_LIMIT :: 8
KEY_LIMIT :: 63
CELL_COUNT :: 48
MAX_PEELS :: 16
MAX_INPUT :: 18

checksum :: proc(key: i64) -> i64 { return key * key + 3 * key + 7 }

location :: proc(key: i64, part: int) -> int {
	x := int(key)
	if part == 0 do return x % 16
	if part == 1 do return 16 + ((3 * x + 5) % 16)
	return 32 + ((5 * x + 9) % 16)
}

write_i64_le :: proc(output: [^]u8, word: int, value: i64) {
	bits := u64(value)
	for byte := 0; byte < 8; byte += 1 { output[word * 8 + byte] = u8(bits >> u64(8 * byte)) }
}

@(export)
invertible_bloom_lookup_table_reconciliation :: proc "c" (input: [^]i64,
		length: c.size_t, output: [^]u8, capacity: c.size_t) -> i64 {
	if input == nil || length < 2 || length > MAX_INPUT + 1 do return -1
	a_raw, b_raw := input[0], input[1]
	if a_raw < 0 || a_raw > SET_LIMIT || b_raw < 0 || b_raw > SET_LIMIT do return -1
	a_count, b_count := int(a_raw), int(b_raw)
	if length != c.size_t(2 + a_count + b_count) do return -1
	for side := 0; side < 2; side += 1 {
		count := a_count
		start := 2
		if side == 1 { count, start = b_count, 2 + a_count }
		previous := i64(-1)
		for i := 0; i < count; i += 1 {
			key := input[start + i]
			if key < 0 || key > KEY_LIMIT || key <= previous do return -1
			previous = key
		}
	}

	counts: [CELL_COUNT]i64
	sums: [CELL_COUNT]i64
	checks: [CELL_COUNT]i64
	for i := 0; i < CELL_COUNT; i += 1 { counts[i], sums[i], checks[i] = 0, 0, 0 }
	for side := 0; side < 2; side += 1 {
		count, start, sign := a_count, 2, i64(1)
		if side == 1 { count, start, sign = b_count, 2 + a_count, -1 }
		for i := 0; i < count; i += 1 {
			key := input[start + i]
			for part := 0; part < 3; part += 1 {
				slot := location(key, part)
				counts[slot] += sign
				sums[slot] += sign * key
				checks[slot] += sign * checksum(key)
			}
		}
	}

	positive: [MAX_PEELS]i64
	negative: [MAX_PEELS]i64
	positive_count, negative_count := 0, 0
	repeated := false
	for peel := 0; peel < MAX_PEELS; peel += 1 {
		zero := true
		for i := 0; i < CELL_COUNT; i += 1 { if counts[i] != 0 || sums[i] != 0 || checks[i] != 0 { zero = false; break } }
		if zero do break
		found, sign, key := false, i64(0), i64(0)
		for i := 0; i < CELL_COUNT; i += 1 {
			if counts[i] != 1 && counts[i] != -1 do continue
			candidate_sign := counts[i]
			candidate := candidate_sign * sums[i]
			if candidate < 0 || candidate > KEY_LIMIT || checks[i] != candidate_sign * checksum(candidate) do continue
			found, sign, key = true, candidate_sign, candidate
			break
		}
		if !found do break
		for i := 0; i < positive_count; i += 1 { if positive[i] == key { repeated = true } }
		for i := 0; i < negative_count; i += 1 { if negative[i] == key { repeated = true } }
		if repeated do break
		if sign > 0 { positive[positive_count] = key; positive_count += 1 }
		else { negative[negative_count] = key; negative_count += 1 }
		for part := 0; part < 3; part += 1 {
			slot := location(key, part)
			counts[slot] -= sign
			sums[slot] -= sign * key
			checks[slot] -= sign * checksum(key)
		}
	}

	zero := true
	for i := 0; i < CELL_COUNT; i += 1 { if counts[i] != 0 || sums[i] != 0 || checks[i] != 0 { zero = false; break } }
	for i := 1; i < positive_count; i += 1 { value := positive[i]; j := i; for j > 0 && positive[j - 1] > value { positive[j] = positive[j - 1]; j -= 1 }; positive[j] = value }
	for i := 1; i < negative_count; i += 1 { value := negative[i]; j := i; for j > 0 && negative[j - 1] > value { negative[j] = negative[j - 1]; j -= 1 }; negative[j] = value }
	staged: [3 + 2 * MAX_PEELS]i64
	words := 0
	staged[words] = 0
	if !repeated && zero { staged[words] = 1 }
	words += 1
	staged[words] = i64(positive_count)
	words += 1
	staged[words] = i64(negative_count)
	words += 1
	for i := 0; i < positive_count; i += 1 { staged[words] = positive[i]; words += 1 }
	for i := 0; i < negative_count; i += 1 { staged[words] = negative[i]; words += 1 }
	required := words * 8
	if output == nil || capacity < c.size_t(required) do return -2
	for i := 0; i < words; i += 1 { write_i64_le(output, i, staged[i]) }
	return i64(required)
}
